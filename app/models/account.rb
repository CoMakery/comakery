class Account < ActiveRecord::Base
  has_many :account_roles
  has_many :roles, through: :account_roles

  def self.find_or_create_from_auth_hash(auth_hash)
    return unless auth_hash["provider"] && auth_hash["code"]
    Account.find_or_create_by!(provider: auth_hash["provider"], uid: auth_hash["code"])
  end
end
