class CreateRevenue < ActiveRecord::Migration[4.2]
  def change
    create_table :revenues do |t|
      t.integer :project_id
      t.string :currency
      t.decimal :amount
      t.text :comment
      t.text :transaction_reference
      t.timestamps null: false
    end
  end
end
