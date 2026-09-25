class ProductsController < ApplicationController
  # 新規登録
  def new
    # 新しい商品を作成するための空のインスタンスを用意
    @product = Product.new
  end

  # 商品登録
  def create
    # フォームから送られたデータを元に新しい商品を作成
    @product = Product.new(product_params)
    # データをデータベースに保存する
    if @product.save
      # 成功した場合、商品一覧へリダイレクト
      redirect_to products_path
    else
      # 失敗した場合、入力内容を保持したままフォームを再表示
      render :new, status: :unprocessable_entity
    end
  end

  # 商品一覧
  def index
    @products = Product.all
  end

  # 商品詳細
  def show
    @product = Product.find(params[:id])
  end

  # 商品編集
  def edit
    @product = Product.find(params[:id])
  end

  # 商品更新
  def update
    @product = Product.find(params[:id])
    if @product.update(product_params)
      # 商品詳細にリダイレクト
      redirect_to product_path
    else
      # 失敗時に編集画面に戻る
      render :edit
    end
  end

  # 商品削除
  def destroy
    @product = Product.find(params[:id])
    @product.destroy
    # 商品一覧にリダイレクト
    redirect_to products_path
  end

  private

    # ストロングパラメータで、フォームから送信されたデータを許可する
    def product_params
      params.require(:product).permit(:name, :description, :price)
    end
end