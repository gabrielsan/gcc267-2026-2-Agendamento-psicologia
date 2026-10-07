# Libera o frontend/BFF a consumir a API. As origens vêm de CORS_ORIGINS
# (separadas por vírgula). O header Authorization é exposto para o cliente
# conseguir ler o JWT devolvido no login.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*ENV.fetch("CORS_ORIGINS", "http://localhost:5173").split(",").map(&:strip))

    resource "*",
      headers: :any,
      expose: [ "Authorization" ],
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
  end
end
