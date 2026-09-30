require "rails_helper"

RSpec.describe "Home", type: :request do
  it "shows profile choices for guests" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Entrar como professor")
    expect(response.body).to include("Entrar como estudante")
    expect(response.body).to include("Entrar como admin")
  end

  it "redirects signed users to the dashboard" do
    sign_in create(:professor)

    get root_path

    expect(response).to redirect_to(dashboard_path)
  end
end
