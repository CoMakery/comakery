# Allow usage of has_and_belongs_to_many to avoid creating a separate model for accounts_projects join table:

class Account < ApplicationRecord
  paginates_per 50
  has_secure_password validations: false

  include EthereumAddressable
  include PrepareImage

  has_one_attached_and_prepare_image :image, resize: '190x190!'

  has_many :projects # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :awards, dependent: :destroy
  has_many :channels, through: :projects
  has_many :authentications, -> { order(updated_at: :desc) }, dependent: :destroy # rubocop:todo Rails/InverseOf
  has_many :authentication_teams, dependent: :destroy
  has_many :teams, through: :authentication_teams
  # rubocop:todo Rails/InverseOf
  has_many :manager_auth_teams, -> { where("manager=true or provider='slack'") }, class_name: 'AuthenticationTeam'
  # rubocop:enable Rails/InverseOf
  has_many :manager_teams, through: :manager_auth_teams, source: :team
  has_many :team_projects, through: :teams, source: :projects
  has_many :award_projects, through: :awards, source: :project
  has_many :channel_projects, through: :channels, source: :project
  has_many :team_awards, through: :team_projects, source: :awards
  # rubocop:todo Rails/InverseOf
  has_many :issued_awards, class_name: 'Award', foreign_key: 'issuer_id' # rubocop:todo Rails/HasManyOrHasOneDependent
  # rubocop:enable Rails/InverseOf
  # rubocop:todo Rails/InverseOf
  has_one :slack_auth, -> { where(provider: 'slack').order('updated_at desc').limit(1) }, class_name: 'Authentication'
  # rubocop:enable Rails/InverseOf
  has_many :interests, dependent: :destroy
  has_many :projects_interested, through: :interests, source: :project
  has_many :project_roles, dependent: :destroy
  has_many :projects_involved, through: :project_roles, source: :project
  has_many :admin_projects, -> { where(project_roles: { role: :admin }) }, through: :project_roles, source: :project
  has_many :experiences # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :verifications, dependent: :destroy
  has_many :admin_awards, through: :admin_projects, source: :awards
  has_many :award_types, through: :projects
  has_many :team_award_types, through: :team_projects, source: :award_types
  has_many :admin_award_types, through: :admin_projects, source: :award_types
  # rubocop:todo Rails/InverseOf
  # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :provided_verifications, class_name: 'Verification', foreign_key: 'provider_id'
  # rubocop:enable Rails/HasManyOrHasOneDependent
  # rubocop:enable Rails/InverseOf
  belongs_to :latest_verification, class_name: 'Verification'
  has_many :account_token_records # rubocop:todo Rails/HasManyOrHasOneDependent
  has_many :account_token_records_synced, -> { where synced: true } # rubocop:todo Rails/InverseOf
  has_many :wallets, dependent: :destroy
  has_many :balances, through: :wallets
  has_one :ore_id_account, dependent: :destroy

  belongs_to :specialty
  belongs_to :managed_mission, class_name: 'Mission'
  has_many :invites, dependent: :destroy

  attr_accessor :invite

  enum deprecated_specialty: {
    audio_video_production: 'Audio Or Video Production',
    community_development: 'Community Development',
    data_gathering: 'Data Gathering',
    marketing_social: 'Marketing & Social',
    software_development: 'Software Development',
    design: 'Design',
    writing: 'Writing',
    research: 'Research'
  }

  scope :sort_by_max_investment_usd_asc, -> { includes(:latest_verification).order('max_investment_usd ASC') }
  scope :sort_by_max_investment_usd_desc, -> { includes(:latest_verification).order('max_investment_usd DESC') }

  attr_accessor :password_required, :name_required, :agreement_required

  # rubocop:todo Rails/UniqueValidationWithoutIndex
  validates :email, presence: true, uniqueness: { scope: %i[managed_mission], case_sensitive: false }
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  validates :password, length: { minimum: 8 }, if: :password_required
  validates :first_name, :last_name, :country, presence: true, if: :name_required
  validates :date_of_birth, presence: { message: 'should be present in correct format' }, if: :name_required
  validates :nickname, uniqueness: true, if: -> { nickname.present? }
  validates :managed_account_id, presence: true, length: { maximum: 256 }, uniqueness: { scope: %i[managed_mission] }, if: -> { managed_mission.present? }
  # rubocop:todo Rails/UniqueValidationWithoutIndex
  validates :public_address, uniqueness: { case_sensitive: false }, allow_nil: true
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  # rubocop:todo Rails/UniqueValidationWithoutIndex
  validates :ethereum_auth_address, ethereum_address: { type: :account }, uniqueness: true, allow_blank: true
  # rubocop:enable Rails/UniqueValidationWithoutIndex
  validates :email, format: { with: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/ }, allow_nil: true
  validates :agreed_to_user_agreement, presence: { message: 'You must agree to the terms of the CoMakery User Agreement to sign up ' }, if: :agreement_required
  validates :linkedin_url, format: { with: %r{\Ahttps:\/\/www.linkedin.com\/.*\z} }, allow_blank: true
  validates :github_url, format: { with: %r{\Ahttps:\/\/github.com\/.*\z} }, allow_blank: true
  validates :dribble_url, format: { with: %r{\Ahttps:\/\/dribbble.com\/.*\z} }, allow_blank: true
  validates :behance_url, format: { with: %r{\Ahttps:\/\/www.behance.net\/.*\z} }, allow_blank: true

  validates_each :linkedin_url, :github_url, :dribble_url, :behance_url, allow_blank: true do |record, attr, value|
    record.errors.add(attr, 'is unsafe') if ApplicationController.helpers.sanitize(value) != value
  end

  validate :validate_age, on: :create
  validate :validate_invite_email, on: :create
  before_validation :populate_managed_account_id, if: -> { managed_mission.present? }
  before_validation :confirm_on_invite
  after_validation :normalize_ethereum_auth_address
  before_save :reset_latest_verification, if: -> { will_save_change_to_first_name? || will_save_change_to_last_name? || will_save_change_to_date_of_birth? || will_save_change_to_country? }

  after_create :populate_awards

  after_update_commit :broadcast_update, if: lambda {
    saved_change_to_first_name? || saved_change_to_last_name? || saved_change_to_email?
  }

  around_destroy :broadcast_destroy

  class << self
    def order_by_award(project)
      award_types = project.award_types.map(&:id).join(',')
      return Account.none if award_types.blank?

      select("accounts.*, (select sum(total_amount) from awards where awards.status in(3,5) and awards.account_id = accounts.id and awards.award_type_id in(#{award_types})) as total").distinct.order('total desc')
    end

    def find_from_uid_channel(uid, channel)
      authentication = Authentication.find_by(uid: uid)
      if authentication
        account = authentication.account
      elsif channel
        account = find_by(email: fetch_email(uid, channel))
      end
      account
    end

    def find_or_create_for_authentication(uid, channel)
      authentication = Authentication.find_by(uid: uid)
      if authentication
        account = authentication.account
      elsif channel
        account = find_or_create_by(email: fetch_email(uid, channel))
        account.nickname = fetch_nickname(uid, channel)
        errors = (account.create_authentication_and_build_team(uid, channel) if account.save)
      end
      [account, errors]
    end

    def fetch_email(uid, channel)
      email = "#{uid}@discordapp.com"
      email = slack_info(uid, channel).user.profile.email || "#{uid}@slackbot.com" if channel.team.slack?
      email
    end

    def fetch_nickname(uid, channel)
      channel.team.discord? ? discord_info(uid)['username'] : slack_info(uid, channel).user.name
    end

    def slack_info(uid, channel)
      @slack_info = Comakery::Slack.new(channel.authentication.token).get_user_info(uid) if uid != @slack_info&.user&.id
      @slack_info
    end

    def discord_info(uid)
      @discord_info = Comakery::Discord.new.user_info(uid)
    end

    def make_everyone_interested(project)
      find_each(batch_size: 500) do |account|
        project.add_account(account)
      end
    end

    def migrate_ethereum_wallet_to_ethereum_auth_address
      # Allow usage of update_column to update even invalid records:
      # rubocop:disable Rails/SkipsModelValidations

      Account.where.not(nonce: nil).find_each do |a|
        a.update_column(:ethereum_auth_address, a.ethereum_wallet) if a.ethereum_wallet.present? && a.email.present? && !a.email.match?(/0x.+@comakery.com/)
      end
    end
  end

  before_save :downcase_email

  def name
    "#{first_name} #{last_name}"
  end

  def whitelabel_involved_projects(whitelabel_mission)
    if whitelabel_mission.present?
      projects_involved.where(mission: whitelabel_mission)
    else
      projects_involved.where(whitelabel: false)
    end
  end

  def create_authentication_and_build_team(uid, channel)
    auth = authentications.create(provider: channel.team.provider, uid: uid)
    channel.team.build_authentication_team auth if auth.valid?
    auth.errors.full_messages.join(', ')
  end

  def downcase_email
    self.email = email.try(:downcase)
  end

  def slack
    @slack ||= Comakery::Slack.get(slack_auth.token)
  end

  def confirm!
    update email_confirm_token: nil
  end

  def award_by_project(project)
    groups = project.awards.completed.where(account: self).group_by { |a| a.award_type.name }
    arr = []
    groups.each do |group|
      arr << { name: group[0], total: group[1].sum(&:total_amount) }
    end
    arr.sort { |i, j| j[:total] <=> i[:total] }
  end

  def total_awards_earned(project)
    project.awards.completed.where(account: self).sum(:total_amount)
  end

  def other_member_projects(scope = nil)
    (scope || Project).joins("
      left join award_types at1 on at1.project_id=projects.id
      left join awards a1 on a1.award_type_id=at1.id
      left join channels on channels.project_id=projects.id
      left join teams on teams.id=channels.team_id
      left join authentication_teams on authentication_teams.team_id=teams.id")
                      .where("((authentication_teams.account_id=#{id} and channels.id is not null) or a1.account_id=#{id}) and projects.account_id <> #{id}").distinct
  end

  def my_projects(scope = nil)
    (scope || Project).joins(:project_admins).distinct.where('projects.account_id = :id OR (project_roles.account_id = :id AND project_roles.role = 1)', id: id)
  end

  def accessable_projects(scope = nil)
    (scope || Project).left_outer_joins(:project_admins, channels: [team: [:authentication_teams]]).distinct.where('projects.visibility in(1) OR projects.account_id = :id OR authentication_teams.account_id = :id OR (project_roles.account_id = :id AND project_roles.role = 1)', id: id)
  end

  def related_projects(scope = nil)
    (scope || Project).left_outer_joins(:project_admins, channels: [team: [:authentication_teams]]).distinct.where('projects.account_id = :id OR ((authentication_teams.account_id = :id OR (project_roles.account_id = :id AND project_roles.role = 1)) AND projects.visibility NOT in(4))', id: id)
  end

  def accessable_award_types(project_scope = nil)
    AwardType.where(project: accessable_projects(project_scope)).or(AwardType.where(project: (project_scope || Project).where(id: award_projects.pluck(:id)).where.not(visibility: :archived)))
  end

  def related_award_types(project_scope = nil)
    AwardType.where(project: related_projects(project_scope))
  end

  def awards_matching_experience(project_scope = nil)
    Award.ready
         .where(award_type: accessable_award_types(project_scope))
         .where('awards.experience_level <= (CASE WHEN (SELECT MAX(id) FROM experiences WHERE (experiences.account_id = :id AND experiences.specialty_id = awards.specialty_id)) IS NULL THEN 0 ELSE (SELECT level FROM experiences WHERE (experiences.account_id = :id AND experiences.specialty_id = awards.specialty_id) LIMIT 1) END)', id: id)
         .where('awards.number_of_assignments_per_user > (SELECT COUNT(*) FROM awards AS assignments WHERE (assignments.cloned_on_assignment_from_id = awards.id AND assignments.account_id = :id))', id: id)
  end

  def related_awards(project_scope = nil)
    Award.where(award_type: related_award_types(project_scope)).where.not('awards.status IN (0, 7) AND awards.number_of_assignments_per_user <= (SELECT COUNT(*) FROM awards AS assignments WHERE (assignments.cloned_on_assignment_from_id = awards.id AND assignments.account_id = :id))', id: id)
  end

  def accessable_awards(project_scope = nil)
    awards_matching_experience(project_scope).or(related_awards(project_scope)).or(awards)
  end

  def experience_for(specialty)
    experiences.find_by(specialty: specialty)&.level.to_i
  end

  def tasks_to_unlock(award)
    award.experience_level - experience_for(award.specialty)
  end

  def confirmed?
    email_confirm_token.nil?
  end

  def involved?(project_id)
    projects_involved.exists? project_id
  end

  def valid_and_underage?
    valid? && date_of_birth.present? && age < 18
  end

  def owned_project?(project)
    project.account_id == id
  end

  def same_team_project?(project)
    team_projects.include?(project)
  end

  def same_team_or_owned_project?(project)
    owned_project?(project) || same_team_project?(project) || award_projects.include?(project)
  end

  def send_reset_password_request(whitelabel_mission)
    update reset_password_token: SecureRandom.hex
    UserMailer.with(whitelabel_mission: whitelabel_mission).reset_password(self).deliver_now
  end

  def age
    return nil unless date_of_birth

    calculate_age
  end

  def to_csv
    Comakery::CSV.generate_multiplatform do |csv|
      csv << ['First Name', 'Last Name', 'Email', 'Nickname', 'Date of Birth', 'Age', 'Country']
      csv << [first_name, last_name, email, nickname, date_of_birth, age, country]
    end
  end

  def awards_csv
    Comakery::CSV.generate_multiplatform do |csv|
      csv << ['Project', 'Award Type', 'Total Amount', 'Issuer', 'Date']
      awards.completed.includes(:award_type, :issuer, project: [:token]).order(:created_at).decorate.each do |award|
        csv << [award.project.title, award.award_type.name, award.total_amount_pretty, award.issuer_display_name, award.created_at.strftime('%b %d, %Y')]
      end
    end
  end

  after_update :check_email_update

  def set_email_confirm_token
    update_column :email_confirm_token, SecureRandom.hex
  end

  def address_for_blockchain(blockchain)
    wallets.find_by(_blockchain: blockchain, primary_wallet: true)&.address
  end

  def ore_id_address_for_blockchain(blockchain)
    wallets.find_by(_blockchain: blockchain, source: :ore_id, primary_wallet: true)&.address
  end

  def wallets_for_blockchain(blockchain)
    wallets.where(_blockchain: blockchain)
  end

  def sync_balances_later
    wallets.pluck(:id, :_blockchain).each do |wallet_id, blockchain|
      Token.where(_blockchain: blockchain).pluck(:id).each do |token_id|
        Balance.find_or_create_by(token_id: token_id, wallet_id: wallet_id).sync_with_blockchain_later
      end
    end
  end

  def whitelabel?
    managed_mission&.whitelabel? || false
  end

  private

    def validate_invite_email
      errors.add(:email, 'must match invite email') if invite&.force_email? && !invite.email.casecmp?(email)
    end

    def confirm_on_invite
      self.email_confirm_token = nil if !confirmed? && invite&.email&.casecmp?(email)
    end

    def validate_age
      errors.add(:date_of_birth, 'You must be at least 18 years old to use CoMakery.') if age && age < 18
    end

    def calculate_age
      now = Time.zone.now.to_date
      result = now.year - date_of_birth.year
      result -= 1 if now.month < date_of_birth.month || now.month == date_of_birth.month && now.day < date_of_birth.day
      result
    end

    def check_email_update
      set_email_confirm_token if saved_change_to_email?
    end

    def populate_managed_account_id
      self.managed_account_id ||= SecureRandom.uuid
    end

    def normalize_ethereum_auth_address
      if ethereum_auth_address.present?
        addr = Eth::Address.new(ethereum_auth_address)
        self.ethereum_auth_address = addr.checksummed if addr.valid?
      end
    end

    def reset_latest_verification
      self.latest_verification = nil
    end

    def populate_awards
      Award.accepted.where(email: email, account_id: nil).find_each do |a|
        a.update(account: self, email: nil)
      end
    end

    def broadcast_update
      wallets.each do |wallet|
        broadcast_replace_to "mission_#{managed_mission&.id}_account_wallets",
                             target: "account_#{id}_wallet_#{wallet.id}",
                             partial: 'accounts/partials/index/wallet',
                             locals: { wallet: wallet }
      end
    end

    def broadcast_destroy
      wallet_ids_to_broadcast = wallet_ids

      yield # perform destroy

      wallet_ids_to_broadcast.each do |wallet_id|
        Turbo::StreamsChannel.broadcast_remove_to(
          "mission_#{managed_mission&.id}_account_wallets",
          target: "account_#{id}_wallet_#{wallet_id}"
        )
      end
    end
end
