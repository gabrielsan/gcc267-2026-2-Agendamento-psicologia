require "rails_helper"

RSpec.describe Professor, type: :model do
  subject(:professor) { build(:professor, crp: "CRP04A") }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_presence_of(:crp) }
  it { is_expected.to have_many(:consultas).dependent(:restrict_with_error) }

  it "validates email uniqueness ignoring case" do
    create(:professor, email: "helena@unilavras.edu.br", crp: "CRP04B")
    professor = build(:professor, email: "HELENA@UNILAVRAS.EDU.BR", crp: "CRP04C")

    expect(professor).not_to be_valid
    expect(professor.errors[:email]).to include("has already been taken")
  end

  it "validates crp uniqueness" do
    create(:professor, crp: "CRP04D")
    professor = build(:professor, crp: "CRP04D")

    expect(professor).not_to be_valid
    expect(professor.errors[:crp]).to include("has already been taken")
  end
end
