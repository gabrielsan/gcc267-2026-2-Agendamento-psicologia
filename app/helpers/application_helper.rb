module ApplicationHelper
  PERFIS = { "admin" => "Admin", "professor" => "Professor", "estagiario" => "Estudante" }.freeze
  STATUS = { "agendada" => "Agendada", "confirmada" => "Confirmada", "realizada" => "Realizada", "cancelada" => "Cancelada", "falta" => "Falta" }.freeze

  def perfil_nome(perfil = current_usuario&.papel) = PERFIS.fetch(perfil.to_s, "Equipe")
  def status_nome(status) = STATUS.fetch(status.to_s, status.to_s)
  def data_hora(valor) = valor ? l(valor, format: "%d/%m/%Y às %H:%M") : "Não informado"
  def iniciais(nome) = nome.to_s.split.first(2).map(&:first).join.upcase

  def status_badge(status)
    tag.span(status_nome(status), class: "badge badge-#{status}")
  end

  def status_para_formulario(consulta)
    permitidos = Consulta::TRANSICOES.fetch(consulta.status_in_database || consulta.status, [])
    permitidos &= Consultas::Atualizar::STATUS_POR_PAPEL.fetch(current_usuario.papel) || permitidos
    ([consulta.status_in_database || consulta.status] + permitidos).uniq.map { |s| [status_nome(s), s] }
  end

  def icone(nome, classe: "icon")
    caminhos = {
      "agenda" => "M8 2v4m8-4v4M3 10h18M5 4h14a2 2 0 0 1 2 2v14H3V6a2 2 0 0 1 2-2ZM7 14h3m4 0h3m-10 4h3",
      "painel" => "M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z",
      "pessoas" => "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2m18 0v-2a4 4 0 0 0-3-3.87M13 3.13a4 4 0 0 1 0 7.75M13 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0Z",
      "seta" => "M5 12h14m-6-6 6 6-6 6",
      "mais" => "M12 5v14M5 12h14",
      "check" => "m5 12 4 4L19 6",
      "relogio" => "M12 8v4l3 2m6-2a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z",
      "sair" => "M9 21H3V3h6m7 14 5-5-5-5M8 12h13",
      "escudo" => "m12 3 8 3v6c0 5-8 9-8 9s-8-4-8-9V6l8-3Zm-4 9 3 3 5-5",
      "livro" => "M12 5v16M3 3c4 0 7 0 9 2 2-2 5-2 9-2v16c-4 0-7 0-9 2-2-2-5-2-9-2V3Z",
      "busca" => "m21 21-5-5M18 10a8 8 0 1 1-16 0 8 8 0 0 1 16 0Z",
      "menu" => "M4 6h16M4 12h16M4 18h16"
    }
    tag.svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.7,
      "stroke-linecap": "round", "stroke-linejoin": "round", class: classe, "aria-hidden": true) do
      tag.path(d: caminhos.fetch(nome, caminhos["agenda"]))
    end
  end
end
