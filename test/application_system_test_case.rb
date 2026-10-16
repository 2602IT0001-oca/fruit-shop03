require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # サーバー描画のフォーム・画面遷移を検証する。JavaScriptは別途Chromiumで確認する。
  driven_by :rack_test
end
