class RemoveScaffoldColumnsFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :age, :integer
    remove_column :users, :password, :string
    change_column_null :users, :name, false
    change_column_null :users, :email, false
  end
end
