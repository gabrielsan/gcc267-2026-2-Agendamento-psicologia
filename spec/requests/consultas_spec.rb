require "rails_helper"

RSpec.describe "Consultas", type: :request do
  describe "GET /consultas" do
    it "filters consultas for signed professors" do
      professor = create(:professor)
      visible = create(:consulta, professor:, patient_name: "Paciente do professor")
      create(:consulta, patient_name: "Paciente de outro professor", starts_at: visible.starts_at + 3.hours)
      sign_in professor

      get consultas_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Paciente do professor")
      expect(response.body).not_to include("Paciente de outro professor")
    end
  end

  describe "POST /consultas" do
    it "allows estagiarios to create consultas" do
      estagiario = create(:estagiario)
      professor = create(:professor)
      sign_in estagiario

      expect do
        post consultas_path, params: { consulta: attributes_for(:consulta).merge(professor_id: professor.id) }
      end.to change(Consulta, :count).by(1)
    end

    it "blocks admins from creating consultas" do
      sign_in create(:admin)
      professor = create(:professor)

      expect do
        post consultas_path, params: { consulta: attributes_for(:consulta).merge(professor_id: professor.id) }
      end.not_to change(Consulta, :count)
      expect(response).to redirect_to(dashboard_path)
    end

    it "blocks professors from creating consultas" do
      professor = create(:professor)
      sign_in professor

      expect do
        post consultas_path, params: { consulta: attributes_for(:consulta).merge(professor_id: professor.id) }
      end.not_to change(Consulta, :count)
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "DELETE /consultas/:id" do
    it "allows admins to delete consultas" do
      consulta = create(:consulta)
      sign_in create(:admin)

      expect do
        delete consulta_path(consulta)
      end.to change(Consulta, :count).by(-1)
    end

    it "blocks estagiarios from deleting consultas" do
      consulta = create(:consulta)
      sign_in consulta.estagiario

      expect do
        delete consulta_path(consulta)
      end.not_to change(Consulta, :count)
      expect(response).to redirect_to(dashboard_path)
    end
  end
end
