require "rails_helper"

RSpec.describe "Frontend HTML", type: :request do
  def entrar(usuario, **extras)
    post "/entrar", params: { usuario: { email: usuario.email, password: "senha123" }, **extras }
  end

  it "oferece os três perfis sem exigir login" do
    get "/"
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Professor", "Estudante", "Admin")
  end

  it "protege o painel e autentica pelo usuário, não pelo perfil escolhido" do
    get "/painel"
    expect(response).to redirect_to(new_usuario_session_path)
    entrar(create(:estagiario), perfil: "admin")
    expect(response).to redirect_to(painel_path)
    follow_redirect!
    expect(response.body).to include("Minha agenda")
    expect(response.body).to include("Login realizado com sucesso.")
    expect(response.body).not_to include("Translation missing")
    get "/professores"
    expect(response).to have_http_status(:forbidden)
  end

  it "recusa senha inválida sem criar sessão" do
    usuario = create(:admin)
    post "/entrar", params: { usuario: { email: usuario.email, password: "errada" } }
    expect(response).to have_http_status(422)
    get "/painel"
    expect(response).to redirect_to(new_usuario_session_path)
  end

  it "encerra a sessão ao sair" do
    entrar(create(:admin))
    delete "/sair"
    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("Você saiu da sua conta.")
    get "/painel"
    expect(response).to redirect_to(new_usuario_session_path)
  end

  it "remove acesso de uma sessão desativada" do
    usuario = create(:estagiario)
    entrar(usuario)
    usuario.update!(ativo: false)
    get "/painel"
    expect(response).to redirect_to(new_usuario_session_path)
  end

  it "não aceita cookie HTML como autenticação da API sem JWT" do
    entrar(create(:admin))
    get "/api/v1/consultas", headers: { "Accept" => "application/json" }
    expect(response).to have_http_status(:unauthorized)
    get "/api/v1/consultas", headers: { "Authorization" => "Bearer invalido", "Accept" => "application/json" }
    expect(response).to have_http_status(:unauthorized)
  end

  it "usa a identidade do JWT mesmo com sessão HTML de outro usuário" do
    consulta = create(:consulta)
    entrar(create(:admin))
    get "/api/v1/me", headers: auth_headers(consulta.estagiario)
    expect(response).to have_http_status(:ok)
    expect(json["usuario"]["id"]).to eq(consulta.estagiario.id)
  end

  it "restringe consultas e dashboard ao professor supervisor" do
    professor = create(:professor)
    minha = create(:consulta, estagiario: create(:estagiario, supervisor: professor), paciente_nome: "Paciente visível")
    outra = create(:consulta, paciente_nome: "Paciente privado")
    entrar(professor)
    get "/painel"
    expect(response.body).to include("Paciente visível")
    expect(response.body).not_to include("Paciente privado")
    get "/consultas/#{outra.id}/edit"
    expect(response).to have_http_status(:forbidden)
    patch "/consultas/#{minha.id}", params: { consulta: { sala: "Sala invasora" } }
    expect(response).to have_http_status(422)
    expect(minha.reload.sala).not_to eq("Sala invasora")
  end

  it "responde com erro legível para filtro e página inválidos" do
    entrar(create(:admin))
    get "/consultas", params: { data: "invalida" }
    expect(response).to have_http_status(:bad_request)
    get "/consultas", params: { pagina: "errada" }
    expect(response).to have_http_status(:bad_request)
  end

  it "exige CSRF para mutações HTML" do
    entrar(create(:admin))
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    expect { post "/professores", params: { professor: { nome: "Sem token" } } }.not_to change(Professor, :count)
    expect(response).to have_http_status(422)
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
