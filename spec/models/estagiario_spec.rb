require "rails_helper"

RSpec.describe Estagiario, type: :model do
  subject(:estagiario) { build(:estagiario, registration: "MAT2026001") }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:registration) }
  it { is_expected.to validate_uniqueness_of(:registration) }
  it { is_expected.to have_many(:consultas).dependent(:restrict_with_error) }
end
