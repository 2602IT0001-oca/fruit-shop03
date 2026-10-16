# Run separately: bundle exec ruby test/order_migration_checks.rb
# Each case migrates an isolated temporary database, leaving development/test data intact.
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "minitest/autorun"
require "tmpdir"

class OrderMigrationChecks < Minitest::Test
  def setup
    @directory = Dir.mktmpdir("fruit-order-migration-")
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: File.join(@directory, "check.sqlite3"))
    pool = ActiveRecord::Base.connection_pool
    @context = ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate"), pool.schema_migration, pool.internal_metadata)
    @database = ActiveRecord::Base.connection
  end

  def teardown
    ActiveRecord::Base.connection_pool.disconnect!
    FileUtils.remove_entry(@directory)
  end

  def test_all_migrations_create_the_final_schema_from_an_empty_database
    @context.migrate
    %w[products users carts cart_items orders order_details].each do |table|
      assert @database.table_exists?(table), table
    end
    assert_equal %w[order_id price product_id quantity], @database.columns(:order_details).map(&:name).intersection(%w[order_id price product_id quantity]).sort
    refute @database.column_exists?(:orders, :product_id)
    refute @database.column_exists?(:orders, :count)
    status = @database.columns(:products).find { |column| column.name == "status" }
    assert_equal 0, status.default
    refute status.null
    assert_empty @database.select_all("PRAGMA foreign_key_check")
  end

  def test_single_product_history_keeps_quantity_historical_price_address_and_timestamps
    @context.migrate(20261016090200)
    insert_legacy_order(total: 600)
    @context.migrate
    order = @database.select_one("SELECT user_id, total_price, address, created_at FROM orders WHERE id = 1")
    assert_equal [ 1, 600, "旧住所", "2026-10-01 12:34:56" ], order.values_at("user_id", "total_price", "address", "created_at")
    detail = @database.select_one("SELECT * FROM order_details WHERE order_id = 1")
    assert_equal [ 1, 1, 3, 200 ], detail.values_at("product_id", "order_id", "quantity", "price")
    assert_equal "2026-10-01 12:34:56", detail["created_at"]
    assert_equal "2026-10-01 12:34:56", detail["updated_at"]
    assert_equal 0, @database.select_value("SELECT status FROM products WHERE id = 1")
    assert_empty @database.select_all("PRAGMA foreign_key_check")
  end

  def test_non_integral_historical_unit_price_stops_migration_without_losing_the_old_order
    @context.migrate(20261016090200)
    insert_legacy_order(total: 601)
    error = assert_raises(StandardError) { @context.migrate }
    assert_includes error.message, "既存注文の数量・金額・住所を確認してください。"
    assert_equal 601, @database.select_value("SELECT total_price FROM orders WHERE id = 1")
    assert @database.column_exists?(:orders, :product_id)
    assert @database.column_exists?(:orders, :count)
    refute @database.table_exists?(:order_details)
  end

  private

  def insert_legacy_order(total:)
    @database.execute(<<~SQL)
      INSERT INTO users (id, name, email, encrypted_password, created_at, updated_at)
      VALUES (1, '旧ユーザー', 'legacy@example.test', '', '2026-10-01 12:34:56', '2026-10-01 12:34:56')
    SQL
    @database.execute(<<~SQL)
      INSERT INTO products (id, name, price, created_at, updated_at)
      VALUES (1, '旧商品', 999, '2026-10-01 12:34:56', '2026-10-01 12:34:56')
    SQL
    @database.execute(<<~SQL)
      INSERT INTO orders (id, user_id, product_id, count, total_price, address, created_at, updated_at)
      VALUES (1, 1, 1, 3, #{Integer(total)}, '旧住所', '2026-10-01 12:34:56', '2026-10-01 12:34:56')
    SQL
  end
end
