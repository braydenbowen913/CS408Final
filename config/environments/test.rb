Rails.application.configure do
  config.action_controller.allow_forgery_protection = false
  config.action_dispatch.show_exceptions = :none
  config.log_level = :warn
end
