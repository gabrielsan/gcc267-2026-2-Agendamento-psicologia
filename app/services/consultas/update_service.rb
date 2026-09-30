module Consultas
  class UpdateService < ApplicationService
    def initialize(consulta:, actor:, params:)
      @consulta = consulta
      @actor = actor
      @params = params
    end

    def call
      return unauthorized unless editable_by_actor?

      consulta.assign_attributes(params)
      consulta.save ? success(consulta) : failure(consulta)
    end

    private

    attr_reader :consulta, :actor, :params

    def editable_by_actor?
      actor.is_a?(Estagiario) && consulta.estagiario_id == actor.id
    end

    def unauthorized
      consulta.errors.add(:base, "Você não tem permissão para editar esta consulta")
      failure(consulta)
    end
  end
end
