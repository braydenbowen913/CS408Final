Rails.application.routes.draw do
  root "home#index"
  get "/api/health", to: "home#health"
end
