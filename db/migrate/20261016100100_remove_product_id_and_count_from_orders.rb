class RemoveProductIdAndCountFromOrders < ActiveRecord::Migration[8.1]
  def up
    remove_reference :orders, :product, foreign_key: true
    remove_column :orders, :count, :integer
    change_column_null :orders, :total_price, false
    change_column_null :orders, :address, false
  end

  def down
    # 複数商品を単品注文へ戻すとデータが欠落するため、自動で戻さない。
    raise ActiveRecord::IrreversibleMigration, "複数商品注文は単品注文に自動変換できません。"
  end
end
