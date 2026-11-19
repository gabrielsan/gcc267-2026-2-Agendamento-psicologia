Rails.application.configure do
  config.eager_load = false
  config.consider_all_requests_local = true
  config.active_support.deprecation = :log
  config.log_level = :info
end
