module Consultas
  class DestroyService < ApplicationService
    def initialize(consulta:, actor:)
      @consulta = consulta
      @actor = actor
    end

    def call
      return unauthorized unless actor.is_a?(Admin)

      consulta.destroy ? success(consulta) : failure(consulta)
    end

    private

    attr_reader :consulta, :actor

    def unauthorized
      consulta.errors.add(:base, "Somente administradores podem excluir consultas")
      failure(consulta)
    end
  end
end
