module Api
  module V1
    # Regras de negócio ficam nos services (app/services/consultas) e as
    # permissões na ConsultaPolicy; o controller só orquestra.
    class ConsultasController < BaseController
      CAMPOS = %i[estagiario_id paciente_nome paciente_telefone paciente_email inicio fim sala status observacoes].freeze

      before_action :carregar_consulta, only: %i[show update destroy]

      # Filtros: ?de=AAAA-MM-DD&ate=AAAA-MM-DD&status=agendada,confirmada
      #          &estagiario_id=ID&professor_id=ID&sala=Sala%201
      def index
        consultas = policy_scope(Consulta).includes(:estagiario, :professor).order(:inicio)
        consultas, meta = paginar(filtrar(consultas))

        render json: { consultas: ConsultaSerializer.colecao(consultas), meta: meta }
      end

      def show
        authorize @consulta
        render json: { consulta: ConsultaSerializer.new(@consulta).as_json }
      end

      def create
        authorize Consulta
        resultado = Consultas::Agendar.call(estagiario: current_usuario, params: consulta_params)

        if resultado.sucesso?
          render json: { consulta: ConsultaSerializer.new(resultado.valor).as_json }, status: :created
        else
          render_falha(resultado)
        end
      end

      def update
        authorize @consulta
        resultado = Consultas::Atualizar.call(consulta: @consulta, params: consulta_params, usuario: current_usuario)

        if resultado.sucesso?
          render json: { consulta: ConsultaSerializer.new(resultado.valor).as_json }
        else
          render_falha(resultado)
        end
      end

      def destroy
        authorize @consulta
        @consulta.destroy!
        head :no_content
      end

      # GET /api/v1/consultas/disponibilidade?data=AAAA-MM-DD[&estagiario_id=ID]
      # Sem estagiario_id, usa o estagiário logado.
      def disponibilidade
        authorize Consulta
        data = ler_data(params.require(:data)).to_date
        estagiario = params[:estagiario_id].present? ? Estagiario.find(params[:estagiario_id]) : current_usuario
        raise ActionController::ParameterMissing, :estagiario_id unless estagiario.estagiario?

        horarios = Consultas::Disponibilidade.call(estagiario: estagiario, data: data)
        render json: { estagiario_id: estagiario.id, data: data, horarios_livres: horarios }
      end

      private

      def carregar_consulta
        @consulta = Consulta.find(params[:id])
      end

      def consulta_params
        params.require(:consulta).permit(*CAMPOS)
      end

      def filtrar(consultas)
        de = ler_data(params[:de])
        ate = ler_data(params[:ate], fim_do_dia: true)

        consultas = consultas.where(inicio: de..) if de
        consultas = consultas.where(inicio: ..ate) if ate
        consultas = consultas.where(status: params[:status].split(",")) if params[:status].present?
        consultas = consultas.where(estagiario_id: params[:estagiario_id]) if params[:estagiario_id].present?
        consultas = consultas.where(professor_id: params[:professor_id]) if params[:professor_id].present?
        consultas = consultas.where(sala: params[:sala].squish) if params[:sala].present?
        consultas
      end
    end
  end
end
