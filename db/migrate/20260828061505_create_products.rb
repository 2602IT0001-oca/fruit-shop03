class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false    # 商品名（必須）
      t.string :string
      t.text :description
      t.integer :price, null: false  # 価格（必須）

      t.timestamps
    end
  end
end
