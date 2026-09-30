require "rails_helper"

RSpec.describe Consultas::CreateService do
  it "creates a consulta for the given estagiario" do
    estagiario = create(:estagiario)
    professor = create(:professor)
    params = attributes_for(:consulta).merge(professor_id: professor.id)

    result = described_class.new(estagiario:, params:).call

    expect(result).to be_success
    expect(result.record).to be_persisted
    expect(result.record.estagiario).to eq(estagiario)
  end
end
