# FruitShop03

Ruby教材の06-01〜07-13に沿ったRailsのフルーツショップです。
商品CRUD、Devise認証、商品画像、セッション/ユーザーカート、複数商品の注文、販売状況、商品検索と並べ替えを実装しています。

教材との対応とバージョン差は[教材との差分](docs/教材との差分.md)を参照してください。

## 開発環境

Ruby 3.4系（クラウドでの検証は3.4.10）、Rails 8.1.3.1、SQLite3、ImageMagickが必要です。
`.ruby-version`は既存の3.4.7指定です。AGENTS.mdでは3.4.10が指定されています。

```sh
bundle install
bin/rails db:prepare
bin/rails server
```

クラウドの既存環境では先に以下を実行します。

```sh
source /workspace/.cloud-tools/activate-fruit-shop03.sh
cd /workspace/fruit-shop03
```

サインアップ画面からアカウントを作成できます。教材どおり管理者フラグを選択したユーザーが商品登録・編集・削除を行い、一般ユーザーがカートと注文を利用します。
ゲストのカートはログイン/新規登録後に引き継がれます。

既存の単品注文は`db:prepare`時に新しい注文明細へ移行します。既存DBを更新する場合は先にバックアップしてください。DBのリセットは不要です。

## テスト

```sh
RAILS_ENV=test bin/rails db:prepare
PARALLEL_WORKERS=2 bin/rails test
RAILS_ENV=test bin/rails test:system
bin/rails zeitwerk:check
bundle exec ruby test/order_migration_checks.rb
```

開発DBのデータや画像は`storage/`に保存され、Gitの追跡対象外です。

注文処理と管理者登録は教材掲載コードに合わせています。確認した制限は[教材との差分](docs/教材との差分.md#コード照合と教材どおりに残した制限)に記載しています。
