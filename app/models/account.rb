class Account < ActiveRecord::Base
  has_many :account_roles, dependent: :destroy
  has_many :authentications, dependent: :destroy
  has_one :slack_auth, -> { where(provider: "slack").order("updated_at desc").limit(1) }, class_name: Authentication
  default_scope { includes(:slack_auth) }
  has_many :account_roles, dependent: :destroy
  has_many :roles, through: :account_roles

  attr_accessor :password, :password_required
  validates :password, length: {minimum: 8}, if: :password_required

  validates_presence_of :email

  before_save :downcase_email

  def downcase_email
    self.email = email.try(:downcase)
  end

  def slack
    @slack ||= Comakery::Slack.get(slack_auth.slack_token)
  end

  # def slack_auth(**scope)
  #   authentications.find_by(**scope.merge(provider: "slack"))
  # end

  def send_award_notifications(**args)
    slack.send_award_notifications(**args)
  end
end
