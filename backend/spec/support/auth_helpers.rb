# Helpers para request specs autenticados.
#
#   get "/api/v1/me", headers: auth_headers(usuario)
module AuthHelpers
  def auth_headers(usuario)
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(usuario, :usuario, nil)
    { "Authorization" => "Bearer #{token}", "Content-Type" => "application/json", "Accept" => "application/json" }
  end

  def json
    JSON.parse(response.body)
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
