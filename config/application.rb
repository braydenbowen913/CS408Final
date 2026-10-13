require_relative "boot"
require "rails"
require "action_view/railtie"
require "action_controller/railtie"
require "rails/test_unit/railtie"
Bundler.require(*Rails.groups)

module Nexus
  class Application < Rails::Application
    config.load_defaults 7.2
    # This landing page stores no data and needs no database or asset build.
    config.eager_load = ENV["RAILS_ENV"] == "production"
    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE") {
      raise "SECRET_KEY_BASE is required in production" if ENV["RAILS_ENV"] == "production"
      "development-only-" * 8
    }
    config.hosts.clear if ENV["RAILS_ENV"] == "production"
    config.logger = ActiveSupport::Logger.new($stdout)
  end
end
