class AuthenticationTeam < ApplicationRecord
  belongs_to :authentication
  belongs_to :account
  belongs_to :team
  has_many :projects, through: :account
  validates :account, :team, :authentication, presence: true

  def channels
    return @channels if @channels
    if slack
      result = GetSlackChannels.call(authentication_team: self)
      @channels = result.channels
    else
      @channels = []
    end
    @channels
  end

  def slack
    @slack ||= Comakery::Slack.get(authentication.token) if authentication.provider=='slack'
  end
end
