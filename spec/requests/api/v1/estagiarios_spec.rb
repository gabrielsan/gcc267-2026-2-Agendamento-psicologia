require "rails_helper"

RSpec.describe "Estagiários" do
  let(:admin) { create(:admin) }
  let(:professor) { create(:professor) }
  let!(:supervisionado) { create(:estagiario, supervisor: professor) }
  let!(:de_outro) { create(:estagiario) }

  it "admin cria estagiário vinculado a um supervisor" do
    payload = { estagiario: { nome: "Nova Estagiária", email: "nova@unilavras.edu.br", senha: "senha123",
                              supervisor_id: professor.id } }
    post "/api/v1/estagiarios", params: payload.to_json, headers: auth_headers(admin)

    expect(response).to have_http_status(:created)
    expect(json["estagiario"]["supervisor"]).to eq("id" => professor.id, "nome" => professor.nome)
  end

  it "exige supervisor válido" do
    payload = { estagiario: { nome: "X", email: "x@unilavras.edu.br", senha: "senha123", supervisor_id: admin.id } }
    post "/api/v1/estagiarios", params: payload.to_json, headers: auth_headers(admin)

    expect(response).to have_http_status(:unprocessable_content)
    expect(json["erros"].join).to include("Supervisor")
  end

  it "admin filtra por supervisor" do
    get "/api/v1/estagiarios", params: { supervisor_id: professor.id }, headers: auth_headers(admin)
    expect(json["estagiarios"].pluck("id")).to eq([ supervisionado.id ])
  end

  it "professor lista só os supervisionados" do
    get "/api/v1/estagiarios", headers: auth_headers(professor)

    expect(response).to have_http_status(:ok)
    expect(json["estagiarios"].pluck("id")).to eq([ supervisionado.id ])
  end

  it "professor não edita estagiários" do
    patch "/api/v1/estagiarios/#{supervisionado.id}", params: { estagiario: { nome: "x" } }.to_json,
                                                      headers: auth_headers(professor)
    expect(response).to have_http_status(:forbidden)
  end

  it "estagiário não lista estagiários" do
    get "/api/v1/estagiarios", headers: auth_headers(supervisionado)
    expect(response).to have_http_status(:forbidden)
  end

  it "admin não exclui estagiário com consultas" do
    create(:consulta, estagiario: supervisionado)
    delete "/api/v1/estagiarios/#{supervisionado.id}", headers: auth_headers(admin)

    expect(response).to have_http_status(:unprocessable_content)
  end
end
