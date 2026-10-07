require "rails_helper"

RSpec.describe EstagiarioPolicy do
  subject { described_class }

  let(:admin) { create(:admin) }
  let(:estagiario) { create(:estagiario) }
  let(:supervisor) { estagiario.supervisor }
  let(:outro_professor) { create(:professor) }

  permissions :create?, :update?, :destroy? do
    it { is_expected.to permit(admin, estagiario) }
    it { is_expected.not_to permit(supervisor, estagiario) }
    it { is_expected.not_to permit(estagiario, estagiario) }
  end

  permissions :show? do
    it { is_expected.to permit(admin, estagiario) }
    it { is_expected.to permit(supervisor, estagiario) }
    it { is_expected.to permit(estagiario, estagiario) }
    it { is_expected.not_to permit(outro_professor, estagiario) }
    it { is_expected.not_to permit(create(:estagiario), estagiario) }
  end

  describe "Scope" do
    let!(:de_outro) { create(:estagiario) }

    def resolve(usuario) = described_class::Scope.new(usuario, Estagiario).resolve

    it { expect(resolve(admin)).to contain_exactly(estagiario, de_outro) }
    it { expect(resolve(supervisor)).to contain_exactly(estagiario) }
    it { expect(resolve(estagiario)).to contain_exactly(estagiario) }
  end
end
