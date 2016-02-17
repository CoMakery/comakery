class Mom
  def account(
    email: Faker::Internet.safe_email,
    password: valid_password
  )
    Account.new email: email
  end

  def account_role(account, role)
    AccountRole.new account: account, role: role
  end

  def admin_role
    role name: 'Admin', key: Role::ADMIN_ROLE_KEY
  end

  def project(subject="Uber for Cats")
    Project.new title: subject, description: "We are going to build #{subject}", repo: "https://github.com/example/#{subject.parameterize}"
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
