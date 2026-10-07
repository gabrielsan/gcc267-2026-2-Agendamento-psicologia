require "rails_helper"

RSpec.describe ConsultaPolicy do
  subject { described_class }

  let(:consulta) { create(:consulta) }
  let(:admin) { create(:admin) }
  let(:supervisor) { consulta.professor }
  let(:outro_professor) { create(:professor) }
  let(:dono) { consulta.estagiario }
  let(:outro_estagiario) { create(:estagiario) }

  permissions :show? do
    it { is_expected.to permit(admin, consulta) }
    it { is_expected.to permit(supervisor, consulta) }
    it { is_expected.to permit(dono, consulta) }
    it { is_expected.not_to permit(outro_professor, consulta) }
    it { is_expected.not_to permit(outro_estagiario, consulta) }
  end

  permissions :create? do
    it { is_expected.to permit(dono, Consulta) }
    it { is_expected.not_to permit(admin, Consulta) }
    it { is_expected.not_to permit(supervisor, Consulta) }
  end

  permissions :update? do
    it { is_expected.to permit(admin, consulta) }
    it { is_expected.to permit(supervisor, consulta) }
    it { is_expected.to permit(dono, consulta) }
    it { is_expected.not_to permit(outro_professor, consulta) }
    it { is_expected.not_to permit(outro_estagiario, consulta) }

    it "estagiário não edita consulta encerrada" do
      consulta.update!(status: :cancelada)
      is_expected.not_to permit(dono, consulta)
    end
  end

  permissions :destroy? do
    it { is_expected.to permit(admin, consulta) }
    it { is_expected.not_to permit(supervisor, consulta) }
    it { is_expected.not_to permit(dono, consulta) }
  end

  describe "Scope" do
    let!(:da_outra_turma) { create(:consulta) }

    def resolve(usuario) = described_class::Scope.new(usuario, Consulta).resolve

    it "admin vê todas" do
      expect(resolve(admin)).to contain_exactly(consulta, da_outra_turma)
    end

    it "professor vê só as supervisionadas" do
      expect(resolve(supervisor)).to contain_exactly(consulta)
    end

    it "estagiário vê só as próprias" do
      expect(resolve(dono)).to contain_exactly(consulta)
    end
  end
end
