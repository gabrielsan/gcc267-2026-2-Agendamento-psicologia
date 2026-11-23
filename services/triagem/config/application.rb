require_relative "boot"
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
# Share the lockfile, but do not boot the web app's frontend/authentication gems.
require "pg"
require "puma"

module Triagem
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    config.time_zone = "America/Sao_Paulo"
    config.paths["db/migrate"] << root.join("../../shared/migrations").to_s
    config.hosts.clear if Rails.env.development?
  end
end
