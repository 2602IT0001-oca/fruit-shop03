class AddStatusToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :status, :integer, default: 0, null: false
    add_index :products, :name, unique: true
  end
end
