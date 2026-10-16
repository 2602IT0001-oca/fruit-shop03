class MypageController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.where(id: current_user.id).find(params[:id])
  end
end
