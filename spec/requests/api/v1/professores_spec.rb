require "rails_helper"

RSpec.describe "Professores" do
  let(:admin) { create(:admin) }
  let!(:professor) { create(:professor, nome: "Ana Ribeiro") }

  describe "como admin" do
    let(:headers) { auth_headers(admin) }

    it "lista e busca" do
      create(:professor, nome: "Carlos Mendes")
      get "/api/v1/professores", params: { busca: "ana" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["professores"].pluck("nome")).to eq([ "Ana Ribeiro" ])
    end

    it "cria professor" do
      payload = { professor: { nome: "Novo Professor", email: "novo@unilavras.edu.br", senha: "senha123", matricula: "P9999" } }
      post "/api/v1/professores", params: payload.to_json, headers: headers

      expect(response).to have_http_status(:created)
      expect(json["professor"]).to include("tipo" => "professor", "email" => "novo@unilavras.edu.br")
      expect(Professor.find(json["professor"]["id"]).valid_password?("senha123")).to be(true)
    end

    it "valida dados obrigatórios" do
      post "/api/v1/professores", params: { professor: { nome: "" } }.to_json, headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["erros"]).to include("Nome não pode ficar em branco", "E-mail não pode ficar em branco")
    end

    it "atualiza sem exigir senha e desativa" do
      patch "/api/v1/professores/#{professor.id}", params: { professor: { ativo: false, senha: "" } }.to_json, headers: headers

      expect(response).to have_http_status(:ok)
      expect(professor.reload.ativo).to be(false)
      expect(professor.valid_password?("senha123")).to be(true)
    end

    it "exclui professor sem vínculos" do
      delete "/api/v1/professores/#{professor.id}", headers: headers
      expect(response).to have_http_status(:no_content)
    end

    it "não exclui professor com estagiários (422)" do
      create(:estagiario, supervisor: professor)
      delete "/api/v1/professores/#{professor.id}", headers: headers

      expect(response).to have_http_status(:unprocessable_content)
      expect(Professor.exists?(professor.id)).to be(true)
    end

    it "não encontra um estagiário pela rota de professores" do
      get "/api/v1/professores/#{create(:estagiario).id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  it "professor vê o próprio cadastro, mas não lista nem cria" do
    get "/api/v1/professores/#{professor.id}", headers: auth_headers(professor)
    expect(response).to have_http_status(:ok)

    get "/api/v1/professores", headers: auth_headers(professor)
    expect(response).to have_http_status(:forbidden)

    post "/api/v1/professores", params: { professor: { nome: "x" } }.to_json, headers: auth_headers(professor)
    expect(response).to have_http_status(:forbidden)
  end

  it "estagiário não acessa professores" do
    get "/api/v1/professores/#{professor.id}", headers: auth_headers(create(:estagiario))
    expect(response).to have_http_status(:forbidden)
  end
end
