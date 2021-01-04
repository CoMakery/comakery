# Allow usage of has_and_belongs_to_many to avoid creating a separate model for accounts_projects join table:
# rubocop:disable Rails/HasAndBelongsToMany

class Project < ApplicationRecord
  include ApiAuthorizable

  nilify_blanks

  # attachment :image
  # attachment :square_image, type: :image
  # attachment :panoramic_image, type: :image
  has_one_attached :image
  has_one_attached :square_image
  has_one_attached :panoramic_image

  belongs_to :account, touch: true
  has_and_belongs_to_many :admins, class_name: 'Account'
  belongs_to :mission, optional: true, touch: true
  belongs_to :token, optional: true, touch: true
  has_many :interests # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :interested, -> { distinct }, through: :interests, source: :account
  has_many :account_token_records, ->(project) { where token_id: project.token_id }, through: :interested, source: :account_token_records

  has_many :transfer_types, dependent: :destroy
  has_many :award_types, inverse_of: :project, dependent: :destroy
  # rubocop:todo Rails/InverseOf
  has_many :ready_award_types, -> { where state: 'public' }, source: :award_types, class_name: 'AwardType'
  # rubocop:enable Rails/InverseOf
  has_many :awards, through: :award_types, dependent: :destroy
  has_many :published_awards, through: :ready_award_types, source: :awards, class_name: 'Award'
  has_many :completed_awards, -> { where.not ethereum_transaction_address: nil }, through: :award_types, source: :awards
  has_many :blockchain_transactions, through: :token
  has_many :channels, -> { order :created_at }, inverse_of: :project, dependent: :destroy

  has_many :contributors, through: :awards, source: :account # TODO: deprecate in favor of contributors_distinct
  has_many :contributors_distinct, -> { distinct }, through: :awards, source: :account
  has_many :teams, through: :account

  accepts_nested_attributes_for :channels, reject_if: :invalid_channel, allow_destroy: true

  enum payment_type: {
    project_token: 1
  }
  enum visibility: { member: 0, public_listed: 1, member_unlisted: 2, public_unlisted: 3, archived: 4 }
  enum status: { active: 0, passive: 1 }

  validates :description, :account, :title, presence: true
  validates :long_id, presence: { message: "identifier can't be blank" }
  # rubocop:todo Rails/UniqueValidationWithoutIndex
  validates :long_id, uniqueness: { message: "identifier can't be blank or not unique" }
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  validates :maximum_tokens, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validate :valid_tracker_url, if: -> { tracker.present? }
  validate :valid_contributor_agreement_url, if: -> { contributor_agreement_url.present? }
  validate :valid_video_url, if: -> { video_url.present? }
  validate :token_changeable, if: -> { token_id_changed? && token_id_was.present? }
  validate :terms_should_be_readonly, if: -> { legal_project_owner_changed? || exclusive_contributions_changed? || confidentiality_changed? }

  before_validation :set_whitelabel, if: -> { mission }
  before_validation :store_license_hash, if: -> { !terms_readonly? && !whitelabel? }
  after_save :udpate_awards_if_token_was_added, if: -> { saved_change_to_token_id? && token_id_before_last_save.nil? }
  after_create :add_owner_as_interested
  after_create :create_default_transfer_types

  scope :featured, -> { order :featured }
  scope :unlisted, -> { where 'projects.visibility in(2,3)' }
  scope :listed, -> { where 'projects.visibility not in(2,3)' }
  scope :visible, -> { where 'projects.visibility not in(2,3,4)' }
  scope :unarchived, -> { where.not visibility: 4 }
  scope :publics, -> { where 'projects.visibility in(1)' }
  scope :with_all_attached_images, -> { with_attached_image.with_attached_square_image.with_attached_panoramic_image }

  delegate :_token_type, to: :token, allow_nil: true
  delegate :_token_type_on_ethereum?, to: :token, allow_nil: true
  delegate :_token_type_on_qtum?, to: :token, allow_nil: true
  delegate :total_awarded, to: :awards, allow_nil: true

  validates :github_url, format: { with: %r{\Ahttps?:\/\/(www\.)?github\.com\/..*\z} }, allow_blank: true
  validates_url :documentation_url, :getting_started_url, :governance_url, :funding_url, :video_conference_url, allow_blank: true
  validates_each :github_url, :documentation_url, :getting_started_url, :governance_url, :funding_url, :video_conference_url, allow_blank: true do |record, attr, value|
    record.errors.add(attr, 'is unsafe') if ApplicationController.helpers.sanitize(value) != value
  end

  def self.assign_project_owner_from(project_or_project_id, email)
    project = project_or_project_id.is_a?(Integer) ? Project.find(project_or_project_id) : project_or_project_id
    raise ArgumentError, 'Project data is invalid' if project.invalid?

    new_owner = Account.find_by(email: email)
    raise ArgumentError, 'Could not find an Account with that email address' if new_owner.blank?

    previous_owner = project.account
    project.safe_add_admin(previous_owner)
    project.account_id = new_owner.id
    project.admins.delete(new_owner)
    project.safe_add_interested(new_owner)
    project.save!
  end

  def assign_project_owner_from(email)
    self.class.assign_project_owner_from(self, email)
  end

  def safe_add_admin(new_admin)
    admins << new_admin unless admins.exists?(new_admin.id)
  end

  def safe_add_interested(interested_account)
    interested << interested_account unless interested_account.interested?(id)
  end

  def top_contributors
    Account
      .with_attached_image
      .select('accounts.*, sum(a1.total_amount) as total_awarded, max(a1.created_at) as last_awarded_at').joins("
      left join awards a1 on a1.account_id=accounts.id and a1.status in(3,5)
      left join award_types on a1.award_type_id=award_types.id
      left join projects on award_types.project_id=projects.id")
      .where('projects.id=?', id)
      .group('accounts.id')
      .order('total_awarded desc, last_awarded_at desc').includes(:specialty).first(5)
  end

  def total_month_awarded
    awards.completed.where('awards.created_at >= ?', Time.zone.today.beginning_of_month).sum(:total_amount)
  end

  def community_award_types
    award_types.where(community_awardable: true)
  end

  def invalid_channel(attributes)
    Channel.invalid_params(attributes)
  end

  def video_id
    # taken from http://stackoverflow.com/questions/5909121/converting-a-regular-youtube-link-into-an-embedded-video
    # Regex from http://stackoverflow.com/questions/3452546/javascript-regex-how-to-get-youtube-video-id-from-url/4811367#4811367
    # Vimeo regex from https://stackoverflow.com/questions/41208456/javascript-regex-vimeo-id

    case video_url
    when %r{youtu\.be/([^\?]*)}
      Regexp.last_match(1)
    when %r{^.*((v/)|(embed/)|(watch\?))\??v?=?([^\&\?]*).*}
      Regexp.last_match(5)
    when %r{(?:www\.|player\.)?vimeo.com/(?:channels/(?:\w+/)?|groups/(?:[^/]*)/videos/|album/(?:\d+)/video/|video/|)(\d+)([a-zA-Z0-9_\-]*)?}i
      Regexp.last_match(1)
    end
  end

  def show_id
    unlisted? ? long_id : id
  end

  def public?
    public_listed? || public_unlisted?
  end

  def unarchived?
    Project.unarchived.where(id: id).present?
  end

  def unlisted?
    member_unlisted? || public_unlisted?
  end

  def percent_awarded
    if maximum_tokens
      total_awarded * 100.0 / maximum_tokens
    else
      0
    end
  end

  def awards_for_chart(max: 1000) # rubocop:todo Metrics/CyclomaticComplexity
    result = []
    recents = awards.completed.includes(:account).limit(max).order('id desc')
    date_groups = recents.group_by { |a| a.created_at.strftime('%Y-%m-%d') }
    date_groups.delete(recents.first.created_at.strftime('%Y-%m-%d')) if awards.completed.count > max
    contributors = {}
    recents.map(&:account).uniq.each do |a|
      name = a&.decorate&.name || 'Others'
      contributors[name] = 0
    end
    date_groups.each do |group|
      item = {}
      item[:date] = group[0]
      item = item.merge(contributors)
      user_groups = group[1].group_by(&:account)
      user_groups.each do |ugroup|
        name = ugroup[0]&.decorate&.name || 'Others'
        item[name] = ugroup[1].sum(&:total_amount)
      end
      result << item
    end
    result
  end

  def ready_tasks_by_specialty(limit_per_specialty = 5)
    awards.ready.includes(:specialty, :project, :issuer, :account, :award_type).group_by(&:specialty).map { |specialty, awards| [specialty, awards.take(limit_per_specialty)] }.to_h
  end

  def stats
    {
      batches: ready_award_types.size,
      tasks: published_awards.in_progress.size,
      interests: interested.size
    }
  end

  def terms_readonly?
    awards.contributed.any?
  end

  def default_award_type
    award_types.find_or_create_by(name: 'Transfers', goal: '—', description: '—')
  end

  def supports_transfer_rules?
    token&._token_type_comakery_security_token?
  end

  def create_default_transfer_types
    TransferType.create_defaults_for(self) if transfer_types.empty?
  end

  private

    def valid_tracker_url
      validate_url(:tracker)
    end

    def valid_contributor_agreement_url
      validate_url(:contributor_agreement_url)
    end

    def valid_video_url
      validate_url(:video_url)
      return if errors[:video_url].present?

      errors[:video_url] << 'must be a link to Youtube or Vimeo video' if video_id.blank?
    end

    def validate_url(attribute_name)
      uri = URI.parse(send(attribute_name) || '')
    rescue URI::InvalidURIError
      uri = nil
    ensure
      errors[attribute_name] << 'must be a valid url' unless uri&.absolute?
      uri
    end

    def token_changeable
      errors.add(:token_id, 'cannot be changed if project has completed tasks') if awards.completed.any?
    end

    def terms_should_be_readonly
      errors.add(:base, 'terms cannot be changed') if terms_readonly?
    end

    def udpate_awards_if_token_was_added
      awards.paid.each { |a| a.update(status: :accepted) }
    end

    def add_owner_as_interested
      interested << account unless account.interested?(id)
    end

    def store_license_hash
      # rubocop:todo Rails/FilePath
      self.agreed_to_license_hash = Digest::SHA256.hexdigest(File.read(Dir.glob(Rails.root.join('lib', 'assets', 'contribution_licenses', 'CP-*.md')).max_by { |f| File.mtime(f) }))
      # rubocop:enable Rails/FilePath
    end

    def set_whitelabel
      self.whitelabel = mission&.whitelabel
    end
end
