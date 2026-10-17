class RegistrationsController < ApplicationController
  before_action :redirect_authenticated_user

  def new
    @user = User.new
  end

  def create
    @user = User.new(params.require(:user).permit(:username, :email, :password, :password_confirmation))
    if @user.save
      sign_in(@user)
      redirect_to dashboard_path, notice: "Welcome to Nexus! Your workspace is ready.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end
end
