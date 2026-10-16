# frozen_string_literal: true

# User scaffoldで作成済みのname・emailは再追加しない。
# NOT NULLは既存のRemoveScaffoldColumnsFromUsersで設定する。
# Recoverableのカラムは既存のAlignUserSchemaWithDeviseで追加する。
class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users do |t|
      t.string :encrypted_password, null: false, default: ""
      t.boolean :admin_flg, null: false, default: false
      t.datetime :remember_created_at

      t.integer :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
    end

    add_index :users, :email, unique: true
  end
end
