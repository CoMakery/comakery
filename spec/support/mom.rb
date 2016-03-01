class Mom
  def account(**attrs)
    @@account_count ||= 0
    @@account_count += 1
    defaults = {
        email: Faker::Internet.safe_email,
        password: valid_password
    }
    Account.new(defaults.merge(attrs))
  end

  def account_role(account, role)
    AccountRole.new account: account, role: role
  end

  def admin_role
    role name: 'Admin', key: Role::ADMIN_ROLE_KEY
  end

  def authentication(**attrs)
    defaults = {
        account: create(:account),
        provider: "slack",
        slack_token: "slack token",
        slack_user_id: "slack user id",
        slack_team_name: "Slack Team",
        slack_team_id: "citizen code id",
        slack_user_name: "johndoe"
    }
    Authentication.new(defaults.merge(attrs))
  end

  def project(owner_account = create(:account), **attrs)
    defaults = {
        title: "Uber for Cats",
        description: "We are going to build amazing",
        tracker: "https://github.com/example/uber_for_cats",
        slack_team_id: "citizen code id",
        slack_team_name: "Citizen Code",
        owner_account: owner_account
    }
    Project.new(defaults.merge(attrs))
  end

  def reward_type(project = create(:project), **attrs)
    defaults = {
        project: project,
        amount: 1337,
        name: "Contribution"
    }
    RewardType.new(defaults.merge(attrs))
  end

  def reward(account = create(:account), issuer = create(:account), **attrs)
    defaults = {
        account: account,
        issuer: issuer,
        description: "Great work",
    }
    defaults[:reward_type] = create(:reward_type) unless attrs[:reward_type]
    Reward.new(defaults.merge(attrs))
  end

  def slack(authentication = create(:authentication))
    Swarmbot::Slack.new(authentication)
  end

  def role(name: 'A Role', key: nil)
    Role.new name: name, key: (key || name)
  end

  def valid_password
    'a password'
  end
end

def mom
  @mom ||= Mom.new
end

def build(thing, *args)
  mom.send(thing, *args)
end

def create(thing, *args)
  mom.send(thing, *args).tap(&:save!)
end
