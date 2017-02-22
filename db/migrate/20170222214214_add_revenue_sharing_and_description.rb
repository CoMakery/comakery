class AddRevenueSharingAndDescription < ActiveRecord::Migration
  def change
    add_column :projects, :revenue_sharing_end_date, :datetime
    add_column :award_types, :description, :text
  end
end
