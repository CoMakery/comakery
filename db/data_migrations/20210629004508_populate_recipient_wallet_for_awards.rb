class PopulateRecipientWalletForAwards < ActiveRecord::DataMigration
  def up
    Award.paid.where(recipient_wallet: nil).where.not(account_id: nil).find_each do |award|
      award.populate_recipient_wallet
      award.save if award.recipient_wallet
    end
  end
end
