require "rails_helper"

RSpec.describe ProfessorPolicy do
  subject { described_class }

  let(:admin) { create(:admin) }
  let(:professor) { create(:professor) }
  let(:estagiario) { create(:estagiario) }

  permissions :index?, :create?, :update?, :destroy? do
    it { is_expected.to permit(admin, professor) }
    it { is_expected.not_to permit(professor, professor) }
    it { is_expected.not_to permit(estagiario, professor) }
  end

  permissions :show? do
    it { is_expected.to permit(admin, professor) }
    it { is_expected.to permit(professor, professor) }
    it { is_expected.not_to permit(create(:professor), professor) }
    it { is_expected.not_to permit(estagiario, professor) }
  end
end
