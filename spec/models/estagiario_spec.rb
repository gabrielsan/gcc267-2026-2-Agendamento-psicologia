require "rails_helper"

RSpec.describe Estagiario do
  it { is_expected.to belong_to(:supervisor).class_name("Professor") }
  it { is_expected.to have_many(:consultas).dependent(:restrict_with_error) }

  it "exige que o supervisor seja um Professor" do
    estagiario = build(:estagiario, supervisor_id: create(:admin).id)

    expect(estagiario).not_to be_valid
    expect(estagiario.errors[:supervisor]).to be_present
  end

  describe "troca de supervisor" do
    it "transfere as consultas futuras em aberto para o novo professor" do
      estagiario = create(:estagiario)
      futura = create(:consulta, estagiario: estagiario)
      cancelada = create(:consulta, estagiario: estagiario, inicio: 3.days.from_now.change(hour: 14))
      cancelada.update!(status: :cancelada)
      passada = create(:consulta, :passada, estagiario: estagiario)
      antigo = estagiario.supervisor
      novo = create(:professor)

      estagiario.update!(supervisor: novo)

      expect(futura.reload.professor).to eq(novo)
      expect(cancelada.reload.professor).to eq(antigo)
      expect(passada.reload.professor).to eq(antigo)
    end
  end
end
