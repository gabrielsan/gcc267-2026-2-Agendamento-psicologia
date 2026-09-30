require "rails_helper"

RSpec.describe "Professores", type: :request do
  describe "POST /professores" do
    it "allows admins to create professors" do
      sign_in create(:admin)

      expect do
        post professores_path, params: { professor: attributes_for(:professor) }
      end.to change(Professor, :count).by(1)
    end

    it "blocks estagiarios from creating professors" do
      sign_in create(:estagiario)

      expect do
        post professores_path, params: { professor: attributes_for(:professor) }
      end.not_to change(Professor, :count)
      expect(response).to redirect_to(dashboard_path)
    end
  end
end
