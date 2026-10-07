# Tokens JWT revogados (logout). Usado pelo devise-jwt.
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist
end
