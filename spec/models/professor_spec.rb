require "rails_helper"

RSpec.describe Professor do
  it { is_expected.to have_many(:estagiarios).with_foreign_key(:supervisor_id).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:consultas_supervisionadas).class_name("Consulta").dependent(:restrict_with_error) }

  it "não é excluído enquanto supervisiona estagiários" do
    professor = create(:estagiario).supervisor

    expect(professor.destroy).to be(false)
    expect(professor.errors.full_messages.join).to include("Não é possível excluir")
  end
end
