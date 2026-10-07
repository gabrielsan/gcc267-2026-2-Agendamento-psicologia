require "rails_helper"

RSpec.describe "Autenticação" do
  let!(:usuario) { create(:estagiario, email: "maria@unilavras.edu.br") }
  let(:headers) { { "Content-Type" => "application/json" } }

  def login(email: "maria@unilavras.edu.br", senha: "senha123")
    post "/api/v1/login", params: { email: email, senha: senha }.to_json, headers: headers
  end

  describe "POST /api/v1/login" do
    it "devolve o usuário e o token JWT no header Authorization" do
      login

      expect(response).to have_http_status(:ok)
      expect(response.headers["Authorization"]).to match(/\ABearer .+/)
      expect(json["usuario"]).to include("id" => usuario.id, "tipo" => "estagiario")
    end

    it "aceita e-mail com maiúsculas e espaços" do
      login(email: "  MARIA@unilavras.edu.br ")
      expect(response).to have_http_status(:ok)
    end

    it "recusa senha errada" do
      login(senha: "errada")

      expect(response).to have_http_status(:unauthorized)
      expect(json).to eq("erros" => [ "E-mail ou senha inválidos." ], "codigo" => "credenciais_invalidas")
      expect(response.headers["Authorization"]).to be_nil
    end

    it "recusa usuário inativo" do
      usuario.update!(ativo: false)
      login

      expect(response).to have_http_status(:unauthorized)
      expect(json["codigo"]).to eq("usuario_inativo")
    end
  end

  describe "DELETE /api/v1/logout" do
    it "revoga o token" do
      login
      token_headers = headers.merge("Authorization" => response.headers["Authorization"])

      delete "/api/v1/logout", headers: token_headers
      expect(response).to have_http_status(:no_content)

      get "/api/v1/me", headers: token_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "acesso sem token" do
    it "devolve 401" do
      get "/api/v1/consultas"

      expect(response).to have_http_status(:unauthorized)
      expect(json["codigo"]).to eq("nao_autenticado")
    end

    it "devolve 401 com token inválido" do
      get "/api/v1/me", headers: { "Authorization" => "Bearer invalido" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/me" do
    it "devolve o usuário logado" do
      get "/api/v1/me", headers: auth_headers(usuario)

      expect(response).to have_http_status(:ok)
      expect(json["usuario"]["supervisor"]).to eq("id" => usuario.supervisor.id, "nome" => usuario.supervisor.nome)
    end
  end
end
