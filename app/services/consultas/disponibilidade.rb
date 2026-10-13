module Consultas
  # Calcula os horários livres de um estagiário em um dia, dentro do
  # expediente da clínica, em blocos de duração fixa.
  class Disponibilidade
    INICIO_EXPEDIENTE = 8   # horas
    FIM_EXPEDIENTE = 20
    DURACAO_PADRAO = 50.minutes
    INTERVALO_ENTRE_INICIOS = 1.hour

    def self.call(...)
      new(...).call
    end

    def initialize(estagiario:, data:, duracao: DURACAO_PADRAO)
      @estagiario = estagiario
      @data = data
      @duracao = duracao
    end

    # => [{ inicio:, fim: }, ...]
    def call
      ocupadas = @estagiario.consultas.ativas.do_dia(@data).pluck(:inicio, :fim)

      blocos.reject do |inicio, fim|
        inicio < Time.current || ocupadas.any? { |oi, of| oi < fim && of > inicio }
      end.map { |inicio, fim| { inicio: inicio, fim: fim } }
    end

    private

    def blocos
      inicio = @data.in_time_zone.change(hour: INICIO_EXPEDIENTE)
      limite = @data.in_time_zone.change(hour: FIM_EXPEDIENTE)
      lista = []
      while inicio + @duracao <= limite
        lista << [ inicio, inicio + @duracao ]
        inicio += INTERVALO_ENTRE_INICIOS
      end
      lista
    end
  end
end
