require "rails_helper"

RSpec.describe Usuario do
  subject { build(:professor) }

  it { is_expected.to validate_presence_of(:nome) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  it { is_expected.to validate_uniqueness_of(:matricula).allow_blank }

  it "não pode ser criado sem um tipo (Admin, Professor ou Estagiario)" do
    usuario = Usuario.new(nome: "X", email: "x@x.com", password: "senha123")
    expect(usuario).not_to be_valid
    expect(usuario.errors[:type]).to be_present
  end

  it "normaliza o e-mail" do
    expect(create(:admin, email: "  ADMIN@Unilavras.EDU.br ").email).to eq("admin@unilavras.edu.br")
  end

  describe "#papel e predicados" do
    it "identifica cada tipo" do
      expect(build(:admin)).to have_attributes(papel: "admin", admin?: true, professor?: false, estagiario?: false)
      expect(build(:professor)).to have_attributes(papel: "professor", admin?: false, professor?: true, estagiario?: false)
      expect(build(:estagiario)).to have_attributes(papel: "estagiario", admin?: false, professor?: false, estagiario?: true)
    end
  end

  describe "#active_for_authentication?" do
    it "bloqueia usuários inativos" do
      expect(build(:admin, ativo: true)).to be_active_for_authentication
      expect(build(:admin, ativo: false)).not_to be_active_for_authentication
    end
  end

  describe ".busca" do
    it "encontra por nome ou e-mail, sem diferenciar maiúsculas" do
      ana = create(:professor, nome: "Ana Ribeiro", email: "ana@unilavras.edu.br")
      create(:professor, nome: "Carlos")

      expect(Professor.busca("ribeiro")).to eq([ ana ])
      expect(Professor.busca("ANA@")).to eq([ ana ])
    end
  end
end
