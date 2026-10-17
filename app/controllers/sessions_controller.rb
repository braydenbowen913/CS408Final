class SessionsController < ApplicationController
  before_action :redirect_authenticated_user, only: [:new, :create]

  def new
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password].to_s)
      sign_in(user)
      redirect_to dashboard_path, notice: "Welcome back!", status: :see_other
    else
      flash.now[:alert] = "Email or password is incorrect."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "You have logged out.", status: :see_other
  end
end
