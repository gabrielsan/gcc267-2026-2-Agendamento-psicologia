require "rails_helper"

RSpec.describe Consulta, type: :model do
  subject(:consulta) { build(:consulta) }

  it { is_expected.to belong_to(:estagiario) }
  it { is_expected.to belong_to(:professor) }
  it { is_expected.to validate_presence_of(:patient_name) }
  it { is_expected.to validate_presence_of(:starts_at) }
  it { is_expected.to validate_presence_of(:ends_at) }

  it "rejects overlapping appointments for the same professor" do
    existing = create(:consulta)
    overlapping = build(:consulta, professor: existing.professor, starts_at: existing.starts_at + 10.minutes, ends_at: existing.ends_at + 10.minutes)

    expect(overlapping).not_to be_valid
    expect(overlapping.errors[:base]).to include("Professor já possui supervisão neste horário")
  end

  it "rejects overlapping appointments for the same estagiario" do
    existing = create(:consulta)
    overlapping = build(:consulta, estagiario: existing.estagiario, starts_at: existing.starts_at + 10.minutes, ends_at: existing.ends_at + 10.minutes)

    expect(overlapping).not_to be_valid
    expect(overlapping.errors[:base]).to include("Estagiário já possui consulta neste horário")
  end

  it "requires room for in-person appointments" do
    consulta.room = nil

    expect(consulta).not_to be_valid
    expect(consulta.errors[:room]).to include("can't be blank")
  end
end
