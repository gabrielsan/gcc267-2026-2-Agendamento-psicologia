require "rails_helper"

RSpec.describe Consultas::DestroyService do
  it "allows admins to destroy consultas" do
    consulta = create(:consulta)
    admin = create(:admin)

    result = described_class.new(consulta:, actor: admin).call

    expect(result).to be_success
    expect(Consulta.exists?(consulta.id)).to be(false)
  end

  it "blocks estagiarios from destroying consultas" do
    consulta = create(:consulta)

    result = described_class.new(consulta:, actor: consulta.estagiario).call

    expect(result).to be_failure
    expect(Consulta.exists?(consulta.id)).to be(true)
  end
end
