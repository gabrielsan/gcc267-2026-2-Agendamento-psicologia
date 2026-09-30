require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  it "requires authentication" do
    get dashboard_path

    expect(response).to redirect_to(root_path)
  end

  it "renders for signed estagiarios" do
    sign_in create(:estagiario)

    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Consultas Psicológicas - Unilavras")
  end

  it "renders a filtered professor view" do
    professor = create(:professor)
    visible = create(:consulta, professor:, patient_name: "Paciente visível")
    create(:consulta, patient_name: "Paciente oculto", starts_at: visible.starts_at + 3.hours)
    sign_in professor

    get dashboard_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Visão do professor")
    expect(response.body).to include("Paciente visível")
    expect(response.body).not_to include("Paciente oculto")
  end
end
