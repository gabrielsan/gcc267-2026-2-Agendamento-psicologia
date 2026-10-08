require "rails_helper"
require "capybara/rspec"

RSpec.describe "Fluxos de atendimento", type: :feature do
  def login(usuario)
    visit "/entrar"
    fill_in "E-mail", with: usuario.email
    fill_in "Senha", with: "senha123"
    click_button "Entrar"
    expect(page).to have_current_path("/painel")
  end

  it "estudante agenda, recebe conflito, corrige e edita a consulta" do
    estagiario = create(:estagiario)
    inicio = 3.days.from_now.change(hour: 10, min: 0)
    create(:consulta, estagiario: estagiario, inicio: inicio, sala: "Sala 1")
    login(estagiario)
    click_link "Nova consulta", match: :first
    fill_in "Nome do paciente", with: "Paciente de teste"
    fill_in "Sala", with: "Sala 2"
    fill_in "Início", with: inicio.strftime("%Y-%m-%dT%H:%M")
    fill_in "Fim", with: (inicio + 50.minutes).strftime("%Y-%m-%dT%H:%M")
    click_button "Salvar consulta"
    expect(page).to have_content("O estagiário já possui uma consulta")
    expect(page).to have_field("Nome do paciente", with: "Paciente de teste")
    fill_in "Início", with: (inicio + 2.hours).strftime("%Y-%m-%dT%H:%M")
    fill_in "Fim", with: (inicio + 170.minutes).strftime("%Y-%m-%dT%H:%M")
    click_button "Salvar consulta"
    expect(page).to have_content("Consulta agendada")
    click_link "Editar consulta"
    fill_in "Nome do paciente", with: "Paciente atualizado"
    click_button "Salvar consulta"
    expect(page).to have_content("Paciente atualizado")
    expect(page).not_to have_button("Excluir consulta")
  end

  it "admin cria, edita, consulta e exclui professor sem vínculos" do
    login(create(:admin))
    click_link "Professores", match: :first
    click_link "Novo professor", match: :first
    fill_in "Nome", with: "Professora de teste"
    fill_in "E-mail", with: "professora@teste.edu.br"
    fill_in "Senha", with: "senha123"
    click_button "Salvar professor"
    expect(page).to have_content("Professor cadastrado")
    click_link "Editar professor"
    fill_in "Nome", with: "Professora atualizada"
    click_button "Salvar professor"
    expect(page).to have_content("Professora atualizada")
    click_button "Excluir professor"
    expect(page).to have_content("Professor excluído")
    expect(Professor.find_by(email: "professora@teste.edu.br")).to be_nil
  end

  it "exibe erro de exclusão com vínculos e permite desativar" do
    professor = create(:estagiario).supervisor
    login(create(:admin))
    visit "/professores/#{professor.id}"
    click_button "Excluir professor"
    expect(page).to have_content("desativar")
    click_link "Editar professor"
    uncheck "Cadastro ativo"
    click_button "Salvar professor"
    expect(professor.reload).not_to be_ativo
  end

  it "professor edita observações da consulta supervisionada" do
    consulta = create(:consulta)
    login(consulta.professor)
    visit "/consultas/#{consulta.id}/edit"
    expect(page).not_to have_field("Sala")
    fill_in "Observações", with: "Acompanhamento confirmado"
    select "Confirmada", from: "Status"
    click_button "Salvar consulta"
    expect(consulta.reload).to have_attributes(status: "confirmada", observacoes: "Acompanhamento confirmado")
  end

  it "admin exclui consulta e visualiza estado vazio" do
    consulta = create(:consulta)
    login(create(:admin))
    visit "/consultas/#{consulta.id}"
    click_button "Excluir consulta"
    expect(page).to have_content("Nenhuma consulta encontrada")
    expect(Consulta.exists?(consulta.id)).to be(false)
  end
end
