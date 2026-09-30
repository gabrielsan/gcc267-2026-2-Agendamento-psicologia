module Consultas
  class CreateService < ApplicationService
    def initialize(estagiario:, params:)
      @estagiario = estagiario
      @params = params
    end

    def call
      consulta = estagiario.consultas.build(params)
      consulta.save ? success(consulta) : failure(consulta)
    end

    private

    attr_reader :estagiario, :params
  end
end
