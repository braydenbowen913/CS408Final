class HomeController < ApplicationController
  def index
  end

  def health
    render json: { status: "ok" }
  end
end
