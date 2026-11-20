require "rails_helper"
require "support/eventos"

RSpec.describe "GET /api/v1/triagens/:consulta_id", type: :request do
  include_context "dados de referencia"

  it "mostra o resultado da triagem e o estado da SAGA" do
    Triagens::ProcessarReservaCriada.call(envelope: montar_envelope(consulta_id: 10, data: dados_reserva(sala: "Sala 99")))

    get "/api/v1/triagens/10"

    expect(response).to have_http_status(:ok)
    corpo = response.parsed_body
    expect(corpo).to include("consulta_id" => 10, "status" => "reprovada", "motivo_codigo" => "SALA_INDISPONIVEL")
    expect(corpo["saga"]).to include("estado" => "TRIAGEM_REPROVADA")
  end

  it "responde 404 para consulta sem triagem" do
    get "/api/v1/triagens/999"

    expect(response).to have_http_status(:not_found)
  end
end
