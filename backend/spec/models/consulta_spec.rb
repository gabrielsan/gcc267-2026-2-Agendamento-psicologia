require "rails_helper"

RSpec.describe Consulta do
  subject(:consulta) { build(:consulta) }

  it { is_expected.to belong_to(:estagiario) }
  it { is_expected.to validate_presence_of(:paciente_nome) }
  it { is_expected.to validate_presence_of(:sala) }
  it { is_expected.to validate_presence_of(:inicio) }
  it { is_expected.to validate_presence_of(:fim) }
  it { is_expected.to allow_value("paciente@email.com").for(:paciente_email) }
  it { is_expected.not_to allow_value("email-invalido").for(:paciente_email) }

  it "começa como agendada" do
    expect(consulta).to be_agendada
  end

  it "define o professor como o supervisor do estagiário" do
    consulta.valid?
    expect(consulta.professor).to eq(consulta.estagiario.supervisor)
  end

  it "não aceita outro professor que não o supervisor" do
    consulta.save!
    consulta.professor = create(:professor)

    expect(consulta).not_to be_valid
    expect(consulta.errors[:professor]).to include("deve ser o supervisor do estagiário")
  end

  it "não aceita status desconhecido" do
    consulta.status = "inexistente"
    expect(consulta).not_to be_valid
    expect(consulta.errors[:status]).to be_present
  end

  describe "horário" do
    it "exige fim depois do início" do
      consulta.fim = consulta.inicio - 1.minute
      expect(consulta).not_to be_valid
      expect(consulta.errors[:fim]).to include("deve ser depois do início")
    end

    it "exige duração entre 30 e 120 minutos" do
      consulta.fim = consulta.inicio + 20.minutes
      expect(consulta).not_to be_valid

      consulta.fim = consulta.inicio + 3.hours
      expect(consulta).not_to be_valid

      consulta.fim = consulta.inicio + 2.hours
      expect(consulta).to be_valid
    end

    it "não permite agendar no passado" do
      consulta.inicio = 1.hour.ago
      consulta.fim = consulta.inicio + 50.minutes
      expect(consulta).not_to be_valid
      expect(consulta.errors[:inicio]).to include("não pode ser no passado")
    end
  end

  describe "transições de status" do
    before { consulta.save! }

    it "permite agendada -> confirmada -> cancelada" do
      expect(consulta.update(status: :confirmada)).to be(true)
      expect(consulta.update(status: :cancelada)).to be(true)
    end

    it "não permite sair de um status final" do
      consulta.update!(status: :cancelada)
      expect(consulta.update(status: :agendada)).to be(false)
      expect(consulta.errors[:status].first).to include("não pode mudar de cancelada para agendada")
    end

    it "só marca como realizada depois do início" do
      expect(consulta.update(status: :realizada)).to be(false)

      travel_to(consulta.inicio + 10.minutes) do
        expect(consulta.update(status: :realizada)).to be(true)
      end
    end
  end

  describe "proteção do banco contra conflitos" do
    it "impede duas consultas ativas do mesmo estagiário no mesmo horário" do
      consulta.save!
      outra = build(:consulta, estagiario: consulta.estagiario, professor: consulta.professor,
                               inicio: consulta.inicio + 10.minutes)

      expect { outra.save!(validate: false) }.to raise_error(ActiveRecord::ExclusionViolation)
    end

    it "permite reaproveitar o horário de uma consulta cancelada" do
      consulta.save!
      consulta.update!(status: :cancelada)

      expect(create(:consulta, estagiario: consulta.estagiario, sala: consulta.sala, inicio: consulta.inicio)).to be_persisted
    end

    it "permite consultas encostadas (uma começa quando a outra termina)" do
      consulta.save!

      expect(create(:consulta, estagiario: consulta.estagiario, sala: consulta.sala, inicio: consulta.fim)).to be_persisted
    end
  end
end
