require "rails_helper"

RSpec.describe Consultas::UpdateService do
  it "allows the owner estagiario to update a consulta" do
    consulta = create(:consulta)

    result = described_class.new(consulta:, actor: consulta.estagiario, params: { patient_name: "Novo nome" }).call

    expect(result).to be_success
    expect(consulta.reload.patient_name).to eq("Novo nome")
  end

  it "blocks another estagiario" do
    consulta = create(:consulta)
    other = create(:estagiario)

    result = described_class.new(consulta:, actor: other, params: { patient_name: "Inválido" }).call

    expect(result).to be_failure
    expect(consulta.reload.patient_name).not_to eq("Inválido")
  end
end
