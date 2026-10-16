class CreateOrderDetails < ActiveRecord::Migration[8.1]
  def up
    create_table :order_details do |t|
      t.references :product, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.integer :price, null: false
      t.timestamps
    end

    # 07-09までの単品注文を明細に移し、既存の注文金額・数量を保持する。
    # 整数の単価へ変換できない履歴は、黙って丸めず移行を中断する。
    invalid = select_value(<<~SQL)
      SELECT COUNT(*) FROM orders
      WHERE count IS NULL OR count <= 0 OR total_price IS NULL
         OR total_price < 0 OR total_price % count != 0 OR address IS NULL
    SQL
    raise "既存注文の数量・金額・住所を確認してください。" if invalid.to_i.positive?

    execute <<~SQL
      INSERT INTO order_details (product_id, order_id, quantity, price, created_at, updated_at)
      SELECT product_id, id, count, total_price / count, created_at, updated_at FROM orders
    SQL
  end

  def down
    drop_table :order_details
  end
end
