class RemoveUnusedStringFromProducts < ActiveRecord::Migration[8.1]
  def change
    remove_column :products, :string, :string
  end
end
