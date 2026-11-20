module Triagens
  # Regras de triagem de uma reserva. As regras rodam em ordem e a primeira que
  # falhar reprova a reserva, devolvendo um código estável (útil para o read
  # model e para o motivo de falha mostrado ao usuário).
  #
  #   HORARIO_NO_PASSADO    início já passou
  #   DURACAO_INVALIDA      duração fora de 30 min a 2 h
  #   FORA_DO_EXPEDIENTE    fora do expediente da clínica (padrão 8h–20h)
  #   SALA_INDISPONIVEL     sala inexistente ou inativa
  #   SUPERVISOR_INVALIDO   professor não é o supervisor ativo do estagiário
  #   ESTAGIARIO_OCUPADO    estagiário já tem outra reserva aprovada no horário
  #   SALA_OCUPADA          sala já está reservada no horário
  class Avaliar
    DURACAO_MINIMA = 30.minutes.to_i
    DURACAO_MAXIMA = 2.hours.to_i
    INICIO_EXPEDIENTE = Integer(ENV.fetch("EXPEDIENTE_INICIO", 8))
    FIM_EXPEDIENTE = Integer(ENV.fetch("EXPEDIENTE_FIM", 20))

    REGRAS = %i[horario_valido dentro_do_expediente sala_ativa supervisor_correto estagiario_livre sala_livre].freeze

    def self.call(...)
      new(...).call
    end

    def initialize(reserva)
      @reserva = reserva
    end

    def call
      REGRAS.each do |regra|
        veredito = send(regra)
        return veredito if veredito
      end
      Veredito.aprovado
    end

    private

    def horario_valido
      return reprovar("HORARIO_NO_PASSADO", "O horário da consulta já passou.") if @reserva.inicio < Time.current

      duracao = @reserva.fim - @reserva.inicio
      return if duracao.between?(DURACAO_MINIMA, DURACAO_MAXIMA)

      reprovar("DURACAO_INVALIDA", "A duração da consulta deve ficar entre 30 minutos e 2 horas.")
    end

    def dentro_do_expediente
      inicio = @reserva.inicio.in_time_zone
      fim = @reserva.fim.in_time_zone
      abertura = inicio.change(hour: INICIO_EXPEDIENTE)
      fechamento = inicio.change(hour: FIM_EXPEDIENTE)
      return if inicio >= abertura && fim <= fechamento

      reprovar("FORA_DO_EXPEDIENTE", "A consulta deve ocorrer entre #{INICIO_EXPEDIENTE}h e #{FIM_EXPEDIENTE}h.")
    end

    def sala_ativa
      return if Sala.ativas.exists?(nome: @reserva.sala)

      reprovar("SALA_INDISPONIVEL", "A sala \"#{@reserva.sala}\" não existe ou está inativa.")
    end

    def supervisor_correto
      supervisao = Supervisao.ativas.find_by(estagiario_id: @reserva.estagiario_id)
      return reprovar("SUPERVISOR_INVALIDO", "O estagiário não tem supervisor ativo cadastrado.") unless supervisao
      return if supervisao.professor_id == @reserva.professor_id

      reprovar("SUPERVISOR_INVALIDO", "O professor informado não é o supervisor do estagiário.")
    end

    def estagiario_livre
      return unless concorrentes.exists?(estagiario_id: @reserva.estagiario_id)

      reprovar("ESTAGIARIO_OCUPADO", "O estagiário já possui outra consulta aprovada nesse horário.")
    end

    def sala_livre
      return unless concorrentes.exists?(sala: @reserva.sala)

      reprovar("SALA_OCUPADA", "A sala \"#{@reserva.sala}\" já está reservada nesse horário.")
    end

    def concorrentes
      ReservaTriagem.ativas
                    .where.not(consulta_id: @reserva.consulta_id)
                    .sobrepostas(@reserva.inicio, @reserva.fim)
    end

    def reprovar(codigo, detalhe)
      Veredito.reprovado(codigo, detalhe)
    end
  end
end
