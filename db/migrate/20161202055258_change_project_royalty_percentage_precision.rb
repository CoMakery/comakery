class ChangeProjectRoyaltyPercentagePrecision < ActiveRecord::Migration
  def up
    change_column :projects, :royalty_percentage, :decimal, precision: 16, scale: 13
  end

  def down
    change_column :projects, :royalty_percentage, :integer
  end
end
