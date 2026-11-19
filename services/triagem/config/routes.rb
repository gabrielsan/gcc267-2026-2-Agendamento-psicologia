Rails.application.routes.draw do
  get "up" => "rails/health#show"
  get "ready", to: ->(_env) {
    ActiveRecord::Base.connection.execute("SELECT 1")
    [200, { "Content-Type" => "application/json" }, ['{"service":"triagem","database":"ok"}']]
  }
end
