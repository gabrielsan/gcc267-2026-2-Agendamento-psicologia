module Api
  module V1
    # Filtro extra no index: ?supervisor_id=ID
    class EstagiariosController < UsuariosController
      private

      def modelo = Estagiario
      def campos_extras = [ :supervisor_id ]

      def filtrar_extra(relacao)
        relacao = relacao.includes(:supervisor)
        params[:supervisor_id].present? ? relacao.where(supervisor_id: params[:supervisor_id]) : relacao
      end
    end
  end
end
