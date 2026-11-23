Rails.application.configure do
  config.eager_load = ENV["CI"].present?
  config.consider_all_requests_local = true
  config.active_support.deprecation = :stderr
end
