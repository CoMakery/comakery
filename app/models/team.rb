class Team < ApplicationRecord
  has_many :authentication_teams, dependent: :destroy
  has_many :accounts, through: :authentication_teams
  has_many :authentications, through: :authentication_teams
  has_many :channels
  has_many :projects, -> { distinct }, through: :channels

  def build_authentication_team(authentication, manager = false)
    auth_team = authentication_teams.find_or_create_by authentication: authentication, account: authentication.account
    auth_team.update manager: manager
  end

  def authentication_team_by_account(account)
    authentication_teams.find_by account_id: account.id
  end

  def channels
    return [] unless discord?
    d_client = Comakery::Discord.new
    @channels ||= d_client.channels(self)
  end

  def parent_channels
    return @parent_channels if @parent_channels
    parents = channels.select { |c| c['parent_id'].nil? }
    @parent_channels = {}
    parents.each do |c|
      @parent_channels[c['id']] = c['name']
    end
    @parent_channels
  end

  def child_channels
    channels.reject { |c| c['parent_id'].nil? }
  end

  def channel_name(channel_id)
    return unless channel_id
    channel = channels.select { |c| c['id'] == channel_id }.first
    channel['name'] if channel
  end

  def channel_for_selects
    return @channel_for_selects if @channel_for_selects
    @channel_for_selects = []
    child_channels.each do |channel|
      parent_name = parent_channels[channel['parent_id']]
      @channel_for_selects << ["#{parent_name} - #{channel['name']}", channel['id']] if parent_name == 'Text Channels'
    end
    @channel_for_selects
  end

  def members
    return [] unless discord?
    d_client = Comakery::Discord.new
    @members ||= d_client.members(self)
  end

  def members_for_select
    members.map { |m| [m['user']['username'], m['user']['id']] }
  end

  def discord?
    provider == 'discord'
  end
end
