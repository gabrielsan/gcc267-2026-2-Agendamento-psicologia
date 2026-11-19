require "rails_helper"

RSpec.describe "Consultas" do
  let(:admin) { create(:admin) }
  let(:estagiario) { create(:estagiario) }
  let(:professor) { estagiario.supervisor }
  let(:inicio) { 3.days.from_now.change(hour: 9, min: 0) }
  let(:payload) do
    { consulta: { paciente_nome: "João da Silva", paciente_email: "joao@email.com", sala: "Sala 1",
                  inicio: inicio.iso8601, fim: (inicio + 50.minutes).iso8601 } }
  end

  describe "POST /api/v1/consultas" do
    it "estagiário agenda uma consulta" do
      post "/api/v1/consultas", params: payload.to_json, headers: auth_headers(estagiario)

      expect(response).to have_http_status(:created)
      expect(json["consulta"]).to include("status" => "agendada", "sala" => "Sala 1", "duracao_minutos" => 50)
      expect(json["consulta"]["professor"]["id"]).to eq(professor.id)
      expect(json["consulta"]["paciente"]["nome"]).to eq("João da Silva")
    end

    it "devolve 422 com codigo conflito_horario em choque de horário" do
      create(:consulta, estagiario: estagiario, inicio: inicio)
      post "/api/v1/consultas", params: payload.to_json, headers: auth_headers(estagiario)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["codigo"]).to eq("conflito_horario")
    end

    it "devolve 422 com as mensagens de validação" do
      payload[:consulta][:paciente_nome] = ""
      post "/api/v1/consultas", params: payload.to_json, headers: auth_headers(estagiario)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json).to eq("erros" => [ "Nome do paciente não pode ficar em branco" ], "codigo" => "invalido")
    end

    it "devolve 400 sem a chave consulta" do
      post "/api/v1/consultas", params: { paciente_nome: "x" }.to_json, headers: auth_headers(estagiario)

      expect(response).to have_http_status(:bad_request)
      expect(json["codigo"]).to eq("parametro_ausente")
    end

    it "professor e admin não criam consultas" do
      [ professor, admin ].each do |usuario|
        post "/api/v1/consultas", params: payload.to_json, headers: auth_headers(usuario)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /api/v1/consultas" do
    let!(:minha) { create(:consulta, estagiario: estagiario, inicio: inicio) }
    let!(:de_outro) { create(:consulta, inicio: inicio + 1.day) }

    it "estagiário vê só as próprias" do
      get "/api/v1/consultas", headers: auth_headers(estagiario)

      expect(json["consultas"].pluck("id")).to eq([ minha.id ])
      expect(json["meta"]).to include("pagina" => 1, "total" => 1)
    end

    it "professor vê só as supervisionadas" do
      get "/api/v1/consultas", headers: auth_headers(professor)
      expect(json["consultas"].pluck("id")).to eq([ minha.id ])
    end

    it "admin vê todas, ordenadas pelo início" do
      get "/api/v1/consultas", headers: auth_headers(admin)
      expect(json["consultas"].pluck("id")).to eq([ minha.id, de_outro.id ])
    end

    it "filtra por período e status" do
      get "/api/v1/consultas", params: { de: (inicio + 1.day).to_date.iso8601 }, headers: auth_headers(admin)
      expect(json["consultas"].pluck("id")).to eq([ de_outro.id ])

      minha.update!(status: :cancelada)
      get "/api/v1/consultas", params: { status: "cancelada" }, headers: auth_headers(admin)
      expect(json["consultas"].pluck("id")).to eq([ minha.id ])
    end

    it "pagina os resultados" do
      get "/api/v1/consultas", params: { por_pagina: 1, pagina: 2 }, headers: auth_headers(admin)

      expect(json["consultas"].pluck("id")).to eq([ de_outro.id ])
      expect(json["meta"]).to include("pagina" => 2, "por_pagina" => 1, "total" => 2, "paginas" => 2)
    end

    it "devolve 400 para data inválida" do
      get "/api/v1/consultas", params: { de: "ontem" }, headers: auth_headers(admin)
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /api/v1/consultas/:id" do
    let(:consulta) { create(:consulta, estagiario: estagiario) }

    it "nega acesso à consulta de outro estagiário" do
      get "/api/v1/consultas/#{consulta.id}", headers: auth_headers(create(:estagiario))
      expect(response).to have_http_status(:forbidden)
    end

    it "devolve 404 para id inexistente" do
      get "/api/v1/consultas/0", headers: auth_headers(admin)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/consultas/:id" do
    let(:consulta) { create(:consulta, estagiario: estagiario) }

    def patch_consulta(usuario, dados)
      patch "/api/v1/consultas/#{consulta.id}", params: { consulta: dados }.to_json, headers: auth_headers(usuario)
    end

    it "professor supervisor confirma a consulta" do
      patch_consulta(professor, status: "confirmada", observacoes: "Confirmado com o paciente")

      expect(response).to have_http_status(:ok)
      expect(json["consulta"]).to include("status" => "confirmada", "observacoes" => "Confirmado com o paciente")
    end

    it "professor que não supervisiona recebe 403" do
      patch_consulta(create(:professor), status: "confirmada")
      expect(response).to have_http_status(:forbidden)
    end

    it "estagiário remarca a própria consulta" do
      novo_inicio = inicio + 1.day
      patch_consulta(estagiario, inicio: novo_inicio.iso8601, fim: (novo_inicio + 1.hour).iso8601)

      expect(response).to have_http_status(:ok)
      expect(consulta.reload.inicio).to eq(novo_inicio)
    end

    it "estagiário cancela a própria consulta e depois não pode mais editá-la" do
      patch_consulta(estagiario, status: "cancelada")
      expect(response).to have_http_status(:ok)

      patch_consulta(estagiario, paciente_nome: "Outro")
      expect(response).to have_http_status(:forbidden)
    end

    it "professor não pode alterar a sala" do
      patch_consulta(professor, sala: "Sala 50")

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["codigo"]).to eq("campo_nao_permitido")
    end
  end

  describe "DELETE /api/v1/consultas/:id" do
    let!(:consulta) { create(:consulta, estagiario: estagiario) }

    it "somente admin exclui" do
      [ estagiario, professor ].each do |usuario|
        delete "/api/v1/consultas/#{consulta.id}", headers: auth_headers(usuario)
        expect(response).to have_http_status(:forbidden)
      end

      expect {
        delete "/api/v1/consultas/#{consulta.id}", headers: auth_headers(admin)
      }.to change(Consulta, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/v1/consultas/disponibilidade" do
    it "lista os horários livres do estagiário logado" do
      create(:consulta, estagiario: estagiario, inicio: inicio)
      get "/api/v1/consultas/disponibilidade", params: { data: inicio.to_date.iso8601 }, headers: auth_headers(estagiario)

      expect(response).to have_http_status(:ok)
      inicios = json["horarios_livres"].map { |h| Time.zone.parse(h["inicio"]).hour }
      expect(inicios).to include(8, 10)
      expect(inicios).not_to include(9)
    end

    it "exige estagiario_id quando quem pergunta não é estagiário" do
      get "/api/v1/consultas/disponibilidade", params: { data: inicio.to_date.iso8601 }, headers: auth_headers(professor)
      expect(response).to have_http_status(:bad_request)

      get "/api/v1/consultas/disponibilidade", params: { data: inicio.to_date.iso8601, estagiario_id: estagiario.id },
                                               headers: auth_headers(professor)
      expect(response).to have_http_status(:ok)
    end
  end
end
