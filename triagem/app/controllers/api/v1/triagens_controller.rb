module Api
  module V1
    # Consulta de apoio: resultado da triagem e estado da SAGA de uma consulta.
    # Serviço interno (sem autenticação); não expor fora da rede dos serviços.
    class TriagensController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound do
        render json: { erro: "triagem não encontrada" }, status: :not_found
      end

      def show
        consulta_id = params[:consulta_id]
        avaliacao = AvaliacaoTriagem.find_by!(consulta_id: consulta_id)
        saga = Saga.find_by(consulta_id: consulta_id)

        render json: {
          consulta_id: avaliacao.consulta_id,
          status: avaliacao.status,
          motivo_codigo: avaliacao.motivo_codigo,
          motivo_detalhe: avaliacao.motivo_detalhe,
          avaliada_em: avaliacao.avaliada_em,
          saga: saga && { estado: saga.estado, motivo_falha: saga.motivo_falha, historico: saga.historico }
        }
      end
    end
  end
end
