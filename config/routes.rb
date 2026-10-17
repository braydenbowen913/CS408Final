Rails.application.routes.draw do
  root "home#index"
  get "/api/health", to: "home#health"
  get "/signup", to: "registrations#new", as: :signup
  post "/signup", to: "registrations#create"
  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout
  get "/dashboard", to: "dashboard#show", as: :dashboard
end
