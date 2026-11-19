require_relative "rails_helper"

RSpec.describe "Triagem infrastructure" do
  it "uses an independent database with no consultation tables" do
    expect(ActiveRecord::Base.connection.tables).to include("outbox_events")
    expect(ActiveRecord::Base.connection.tables).not_to include("usuarios", "consultas")
    expect(defined?(Consulta)).to be_nil
  end

  it "reports readiness using its own database" do
    response = Rack::MockRequest.new(Rails.application).get("/ready")
    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)).to eq("service" => "triagem", "database" => "ok")
  end

  it "persists triagem events locally with the shared envelope" do
    event = nil
    ActiveRecord::Base.transaction do
      event = Messaging::Outbox.record!(event_type: "triagem.reprovada", consulta_id: "42",
        data: { motivo: "Sala indisponivel", reserva_event_id: SecureRandom.uuid })
    end
    expect(event.reload.producer).to eq("triagem")
    expect(event.data).to include("motivo" => "Sala indisponivel")
    expect(event.published_at).to be_nil
  end
end
