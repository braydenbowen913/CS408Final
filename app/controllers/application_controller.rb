class ApplicationController < ActionController::Base
  helper_method :current_user

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def require_login
    response.headers["Cache-Control"] = "no-store"
    redirect_to login_path, alert: "Please log in to view your workspace." unless current_user
  end

  def redirect_authenticated_user
    redirect_to dashboard_path if current_user
  end

  def sign_in(user)
    reset_session
    session[:user_id] = user.id
  end
end
