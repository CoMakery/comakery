require 'bigdecimal'

class Award < ApplicationRecord
  paginates_per 50

  include BlockchainTransactable
  include RansackReorder
  include PrepareImage

  EXPERIENCE_LEVELS = {
    'New Contributor' => 0,
    'Demonstrated Skills' => 3,
    'Established Contributor' => 10
  }.freeze

  STARTED_TASKS_PER_CONTRIBUTOR = 5
  QUANTITY_PRECISION = 2

  has_one_attached_and_prepare_image :image
  has_one_attached_and_prepare_image :submission_image

  attribute :specialty_id, :integer, default: -> { Specialty.default.id }
  add_special_orders %w[account_first_name issuer_first_name]

  belongs_to :account, optional: true, touch: true
  belongs_to :authentication, optional: true
  belongs_to :award_type, touch: true
  belongs_to :transfer_type, optional: false
  belongs_to :issuer, class_name: 'Account', touch: true
  belongs_to :channel, optional: true
  belongs_to :specialty
  belongs_to :recipient_wallet, class_name: 'Wallet', optional: true
  # rubocop:todo Rails/InverseOf
  belongs_to :cloned_from, class_name: 'Award', foreign_key: 'cloned_on_assignment_from_id', counter_cache: :assignments_count, touch: true
  # rubocop:enable Rails/InverseOf
  # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :assignments, class_name: 'Award', foreign_key: 'cloned_on_assignment_from_id' # rubocop:todo Rails/InverseOf
  # rubocop:enable Rails/HasManyOrHasOneDependent
  has_one :team, through: :channel
  has_one :project, through: :award_type
  has_one :token, through: :project

  validates :proof_id, :award_type, :name, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :number_of_assignments, :number_of_assignments_per_user, numericality: { greater_than: 0 }
  validates :number_of_assignments_per_user, numericality: { less_than_or_equal_to: :number_of_assignments }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
  validates :name, length: { maximum: 100 }
  validates :why, length: { maximum: 500 }
  validates :description, length: { maximum: 500 }
  validates :message, length: { maximum: 150 }
  validates :requirements, length: { maximum: 1000 }
  validates :proof_link, length: { maximum: 150 }
  validates :proof_link, exclusion: { in: %w[http:// https://], message: 'is not valid URL' }
  validates :proof_link, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: 'must include protocol (e.g. https://)' }, if: -> { proof_link.present? }
  validates :submission_url, exclusion: { in: %w[http:// https://], message: 'is not valid URL' }
  validates :submission_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: 'must include protocol (e.g. https://)' }, if: -> { submission_url.present? }
  validates :experience_level, inclusion: { in: EXPERIENCE_LEVELS.values }, allow_nil: true
  validates :account, presence: true, if: -> { status == 'accepted' && email.blank? }
  validates :expires_in_days, presence: true, numericality: { greater_than: 0 }
  validates :lockup_schedule_id, presence: true, if: -> { project&.token&.token_type&.is_a?(TokenType::TokenReleaseSchedule) }
  validates :commencement_date, presence: true, if: -> { project&.token&.token_type&.is_a?(TokenType::TokenReleaseSchedule) }
  validates :lockup_schedule_id, absence: true, unless: -> { project&.token&.token_type&.is_a?(TokenType::TokenReleaseSchedule) }
  validates :commencement_date, absence: true, unless: -> { project&.token&.token_type&.is_a?(TokenType::TokenReleaseSchedule) }
  validates :transfer_type_id, inclusion: { in: ->(r) { r.project.transfer_types.pluck(:id) } }, if: :project

  validate :total_amount_fits_into_project_budget
  validate :contributor_doesnt_have_too_many_started_tasks, if: -> { status == 'started' }
  validate :contributor_doesnt_reach_maximum_assignments, if: -> { status == 'started' }
  validate :cancellation, if: -> { status_changed? && status_was.in?(%w[rejected paid cancelled]) && status == 'cancelled' }
  validate :recipient_wallet_belongs_to_account, if: -> { recipient_wallet_id.present? }
  validate :recipient_wallet_and_token_in_same_network, if: -> { recipient_wallet_id.present? }

  before_validation :ensure_proof_id_exists
  before_validation :calculate_total_amount
  before_validation :set_paid_status_if_project_has_no_token, if: -> { status == 'accepted' && !project&.token }
  before_validation :make_unpublished_if_award_type_is_not_ready, if: -> { status == 'ready' && !award_type&.public_state? }
  before_validation :store_license_hash, if: -> { status == 'started' && agreed_to_license_hash.nil? }
  before_validation :set_expires_at, if: -> { status == 'started' && expires_at.nil? }
  before_validation :clear_expires_at, if: -> { status == 'submitted' && expires_at.present? }
  before_validation :set_transferred_at, if: -> { status == 'paid' && transferred_at.nil? }
  before_validation :set_default_transfer_type
  before_validation :populate_recipient_wallet, if: -> { paid? && !recipient_wallet }
  before_destroy :abort_destroy
  after_save :update_account_experience, if: -> { completed? }
  after_save :add_account_as_interested, if: -> { account }

  after_update_commit :broadcast_update, if: :saved_change_to_transferred_at?

  scope :completed, -> { where 'awards.status in(3,5)' }
  scope :completed_or_cancelled, -> { where 'awards.status in(3,5,6)' }
  scope :listed, -> { where 'awards.status not in(6,7)' }
  scope :in_progress, -> { where 'awards.status in(0,1,2,3)' }
  scope :contributed, -> { where 'awards.status in(1,2,3,4,5)' }
  scope :not_burned, -> { joins(:transfer_type).where.not(transfer_types: { name: 'burn' }) }

  scope :transfer_ready, ->(blockchain) { accepted.joins(account: :wallets).where(wallets: { _blockchain: blockchain, primary_wallet: true }) }
  scope :transfer_blocked_by_wallet, ->(blockchain) { accepted.where.not(id: transfer_ready(blockchain).group('awards.id').pluck(:id)) }

  scope :filtered_for_view, lambda { |filter, account|
    case filter
    when 'ready'
      where(status: :ready, account: [nil, account]).or(where(status: :invite_ready, account: account))
    when 'started'
      where(status: :started).where(account: account)
    when 'submitted'
      where(status: %i[submitted accepted], account: account)
    when 'to review'
      where(status: :submitted).where(award_type: account.admin_award_types + account.award_types)
    when 'to pay'
      where(status: :accepted).where(award_type: account.admin_award_types + account.award_types)
    when 'done'
      where(status: %i[paid rejected], account: account).or(where(status: %i[paid rejected], award_type: account.admin_award_types + account.award_types))
    else
      none
    end
  }

  scope :with_all_attached_images, -> { with_attached_image.with_attached_submission_image }

  enum status: { ready: 0, started: 1, submitted: 2, accepted: 3, rejected: 4, paid: 5, cancelled: 6, invite_ready: 7 }
  enum source: { earned: 0, bought: 1, mint: 2, burn: 3 }

  delegate :_blockchain, :blockchain, to: :token

  def self.ransackable_scopes(_ = nil)
    %i[transfer_ready transfer_blocked_by_wallet]
  end

  def self.total_awarded
    completed.sum(:total_amount)
  end

  # Used in ransack_reorder
  def self.prepare_ordering_by_account_first_name(scope)
    scope.joins('left join accounts AS recipients ON awards.account_id = recipients.id').select('awards.*, recipients.first_name, recipients.last_name')
  end

  def self.account_first_name_order_string(direction)
    "recipients.first_name #{direction}, recipients.last_name #{direction}, awards.created_at ASC"
  end

  def self.prepare_ordering_by_issuer_first_name(scope)
    scope.joins('left join accounts AS issuers ON awards.issuer_id = issuers.id').select('awards.*, issuers.first_name, issuers.last_name')
  end

  def self.issuer_first_name_order_string(direction)
    "issuers.first_name #{direction}, issuers.last_name #{direction}, awards.created_at ASC"
  end

  def self.grouped_type_counts
    group(:transfer_type_id).pluck(:transfer_type_id, 'count(awards.transfer_type_id)').to_h
  end

  def ensure_proof_id_exists
    self.proof_id ||= SecureRandom.base58(44) # 58^44 > 2^256
  end

  def self_issued?
    account_id == issuer_id
  end

  def amount_to_send
    if project.token
      project.token&.to_base_unit(total_amount)&.to_i
    else
      total_amount.to_i
    end
  end

  def recipient_auth_team
    account.authentication_teams.find_by team_id: channel.team_id if channel
  end

  def send_confirm_email
    unless channel
      if confirmed?
        UserMailer.incoming_award_notifications(self).deliver_now
      else
        UserMailer.send_award_notifications(self).deliver_now
      end
    end
  end

  def discord_client
    @discord_client ||= Comakery::Discord.new
  end

  def slack_client
    auth_team = team.authentication_team_by_account issuer
    token = auth_team.authentication.token
    Comakery::Slack.get(token)
  end

  def send_award_notifications
    return unless channel

    if team.discord?
      discord_client.send_message self
    else
      slack_client.send_award_notifications(award: self)
    end
  end

  def matching_experience_for?(account)
    experience_level.to_i <= account.experience_for(specialty)
  end

  def confirm!(account)
    update confirm_token: nil, account: account
  end

  def confirmed?
    confirm_token.blank?
  end

  def discord?
    team&.discord?
  end

  def completed?
    %w[accepted paid].include? status
  end

  def can_be_edited?
    (ready? || invite_ready?) && !cloned? && !any_clones?
  end

  def can_be_assigned?
    (ready? || invite_ready?)
  end

  def cloned?
    cloned_on_assignment_from_id.present?
  end

  def any_clones?
    !assignments.empty?
  end

  def cloneable?
    number_of_assignments.to_i > 1
  end

  def should_be_cloned?
    assignments.size + 1 < number_of_assignments.to_i
  end

  def can_be_cloned_for?(account)
    (account.awards.started.count < STARTED_TASKS_PER_CONTRIBUTOR) && !reached_maximum_assignments_for?(account)
  end

  def reached_maximum_assignments_for?(account)
    assignments.where(account: account).size >= number_of_assignments_per_user.to_i
  end

  def clone_on_assignment
    new_award = dup
    new_award.cloned_on_assignment_from_id = id
    new_award.number_of_assignments = 1
    new_award.number_of_assignments_per_user = 1
    new_award.save!
    new_award
  end

  def possible_quantity
    if cancelled? || rejected?
      BigDecimal(0)
    else
      (number_of_assignments || 1) - assignments.size
    end
  end

  def possible_total_amount
    if cancelled? || rejected?
      BigDecimal(0)
    else
      total_amount * possible_quantity
    end
  end

  def expire!
    if cloned?
      self.status = :cancelled
    else
      self.status = :ready
      self.expires_at = nil
      self.account = nil
    end

    save
  end

  def expiring_notification_sent
    update(notify_on_expiration_at: nil)
  end

  def run_expiration
    if started? && expires_at && (expires_at < Time.current)
      begin
        TaskMailer.with(award: self).task_expired_for_account.deliver_now
        TaskMailer.with(award: self).task_expired_for_issuer.deliver_now
      ensure
        expire!
      end
    end
  end

  def run_expiring_notification
    if started? && notify_on_expiration_at && (notify_on_expiration_at < Time.current)
      begin
        TaskMailer.with(award: self).task_expiring.deliver_now
      ensure
        expiring_notification_sent
      end
    end
  end

  def recipient_address
    return recipient_wallet.address if recipient_wallet_id.present?

    account&.address_for_blockchain(token&._blockchain)
  end

  def needs_wallet?
    recipient_address.blank?
  end

  def account_frozen?
    account.account_token_records.find_by(token: token)&.account_frozen?
  end

  def account_verification_unknown?
    account.latest_verification.nil?
  end

  def account_verification_failed?
    if account.latest_verification
      account.latest_verification.failed?
    else
      false
    end
  end

  def payment_blocked?
    !accepted? || needs_wallet? || account_frozen? || account_verification_unknown? || account_verification_failed?
  end

  def handle_tx_hash(hash, issuer)
    update!(ethereum_transaction_address: hash, status: :paid, issuer: issuer)
  end

  def handle_tx_receipt(receipt)
    receipt = JSON.parse(receipt)
    success = receipt['status']
    status = success ? :paid : :accepted

    update!(transaction_success: success, status: status)
  end

  def handle_tx_error(error)
    update!(transaction_error: error, status: :accepted)
  end

  def populate_recipient_wallet
    self.recipient_wallet = account&.wallets&.find_by(address: recipient_address, _blockchain: token&._blockchain)
  end

  delegate :image, to: :team, prefix: true, allow_nil: true

  private

    def broadcast_update
      broadcast_replace_to :transfer_transferred_date,
                           target: "transfer_#{id}_transferred_date",
                           partial: 'dashboard/transfers/transferred_date',
                           locals: { transfer: self }
    end

    def calculate_total_amount
      self.total_amount = BigDecimal(amount || 0) * BigDecimal(quantity || 1)
    end

    def set_paid_status_if_project_has_no_token
      self.status = 'paid'
    end

    def make_unpublished_if_award_type_is_not_ready
      self.status = 'invite_ready'
    end

    def total_amount_fits_into_project_budget # rubocop:todo Metrics/CyclomaticComplexity
      return if project&.maximum_tokens.nil? || project&.maximum_tokens&.zero?

      errors[:base] << "Sorry, you can't exceed the project's budget" if possible_total_amount + BigDecimal(project&.awards&.where&.not(id: id)&.sum(&:possible_total_amount) || 0) > BigDecimal(project&.maximum_tokens)
    end

    def recipient_wallet_belongs_to_account
      return if account&.wallets&.exists?(id: recipient_wallet_id)

      errors[:recipient_wallet_id] << "wallet doesn't belong to the specified account"
    end

    def recipient_wallet_and_token_in_same_network
      return if recipient_wallet._blockchain == token&._blockchain

      errors[:recipient_wallet_id] << 'wallet and token are not in the same network'
    end

    def abort_destroy
      unless can_be_edited?
        errors[:base] << "#{status.capitalize} task can't be deleted"
        throw :abort
      end
    end

    def contributor_doesnt_have_too_many_started_tasks
      errors.add(:base, "Sorry, you can't start more than #{STARTED_TASKS_PER_CONTRIBUTOR} tasks") if account && account.awards.started.count >= STARTED_TASKS_PER_CONTRIBUTOR
    end

    def contributor_doesnt_reach_maximum_assignments
      errors.add(:base, 'Sorry, you already did the task maximum times allowed') if account && reached_maximum_assignments_for?(account)
    end

    def update_account_experience
      Experience.increment_for(account, specialty)
    end

    def add_account_as_interested
      project.project_interested << account unless account.involved?(project.id)
    end

    def store_license_hash
      self.agreed_to_license_hash = project.agreed_to_license_hash
    end

    def set_expires_at
      self.updated_at = Time.current
      self.expires_at = expires_in_days.days.since(updated_at)
      self.notify_on_expiration_at = (expires_in_days.days * 0.75).since(updated_at)
    end

    def clear_expires_at
      self.expires_at = nil
      self.notify_on_expiration_at = nil
    end

    def set_transferred_at
      self.updated_at = Time.current
      self.transferred_at = updated_at
    end

    def set_default_transfer_type
      self.transfer_type ||= project&.transfer_types&.find_by(name: 'earned')
    end

    def cancellation
      errors.add(:base, "#{status_was.capitalize} task/transfer can't be cancelled")
    end
end
