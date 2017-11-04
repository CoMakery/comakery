class AddQuantityToAwards < ActiveRecord::Migration[4.2]
  def change
    add_column :awards, :quantity, :numeric, default: 1.0
    add_column :awards, :total_amount, :integer
    add_column :awards, :unit_amount, :integer
  end
end
