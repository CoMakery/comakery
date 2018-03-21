class Account < ApplicationRecord
  has_secure_password validations: false
  attachment :image
  include EthereumAddressable

  has_many :account_roles, dependent: :destroy
  has_many :authentications, -> { order(updated_at: :desc) }, dependent: :destroy
  has_many :authentication_teams, dependent: :destroy
  has_many :teams, through: :authentication_teams
  has_many :team_projects, through: :teams, source: :projects
  has_many :team_awards, through: :team_projects, source: :awards
  has_many :awards, dependent: :destroy
  has_one :slack_auth, -> { where(provider: 'slack').order('updated_at desc').limit(1) }, class_name: 'Authentication'
  default_scope { includes(:slack_auth) }
  has_many :roles, through: :account_roles
  has_many :projects
  has_many :payments
  has_many :channels, through: :projects
  validates :email, presence: true, uniqueness: true
  attr_accessor :password_required
  validates :password, length: { minimum: 8 }, if: :password_required

  validates :ethereum_wallet, ethereum_address: { type: :account } # see EthereumAddressable

  before_save :downcase_email

  def downcase_email
    self.email = email.try(:downcase)
  end

  def slack
    @slack ||= Comakery::Slack.get(slack_auth.token)
  end

  def send_award_notifications(**args)
    slack.send_award_notifications(**args)
  end

  def confirmed?
    email_confirm_token.nil?
  end

  def confirm!
    update email_confirm_token: nil
  end

  def name
    full_name = [first_name, last_name].reject(&:blank?).join(' ')
    full_name.blank? ? email : full_name
  end

  def total_awards_earned(project)
    project.awards.where(account: self).sum(:total_amount)
  end

  def total_awards_paid(project)
    project.payments.where(account: self).sum(:quantity_redeemed)
  end

  def total_awards_remaining(project)
    total_awards_earned(project) - total_awards_paid(project)
  end

  def total_revenue_paid(project)
    project.payments.where(account: self).sum(:total_value)
  end

  def total_revenue_unpaid(project)
    project.share_of_revenue_unpaid(total_awards_remaining(project))
  end

  def percent_unpaid(project)
    return BigDecimal('0') if project.total_awards_outstanding.zero?
    precise_percentage = (BigDecimal(total_awards_remaining(project)) * 100) / BigDecimal(project.total_awards_outstanding)
    precise_percentage.truncate(8)
  end

  def public_projects
    Project.publics.where.not(id: team_projects.map(&:id))
  end

  def same_team_project?(project)
    team_projects.include?(project)
  end

  def send_reset_password_request
    update reset_password_token: SecureRandom.hex
    UserMailer.reset_password(self).deliver_now
  end
end
