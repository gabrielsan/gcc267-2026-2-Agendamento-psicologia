module Api
  module V1
    # CRUD genérico de usuários, compartilhado por ProfessoresController e
    # EstagiariosController. As subclasses definem:
    #   - modelo            (ex.: Professor)
    #   - chave_parametros  (ex.: :professor)
    #   - campos_extras     (ex.: [:supervisor_id])
    #   - filtrar_extra(relacao) para filtros próprios
    #
    # Filtros comuns no index: ?busca=texto&ativo=true|false
    class UsuariosController < BaseController
      CAMPOS = %i[nome email senha matricula telefone ativo].freeze

      before_action :carregar_registro, only: %i[show update destroy]

      def index
        authorize modelo
        registros = policy_scope(modelo).order(:nome)
        registros = registros.busca(params[:busca]) if params[:busca].present?
        registros = registros.where(ativo: ActiveModel::Type::Boolean.new.cast(params[:ativo])) if params.key?(:ativo)
        registros, meta = paginar(filtrar_extra(registros))

        render json: { chave_colecao => UsuarioSerializer.colecao(registros), meta: meta }
      end

      def show
        authorize @registro
        render json: { chave_parametros => UsuarioSerializer.new(@registro).as_json }
      end

      def create
        @registro = modelo.new(atributos)
        authorize @registro

        if @registro.save
          render json: { chave_parametros => UsuarioSerializer.new(@registro).as_json }, status: :created
        else
          render_invalido(@registro)
        end
      end

      def update
        authorize @registro

        if @registro.update(atributos)
          render json: { chave_parametros => UsuarioSerializer.new(@registro).as_json }
        else
          render_invalido(@registro)
        end
      end

      # Usuários com vínculos (consultas, estagiários) não são excluídos:
      # devolve 422 e o admin pode desativá-los com { "ativo": false }.
      def destroy
        authorize @registro

        if @registro.destroy
          head :no_content
        else
          render_invalido(@registro)
        end
      end

      private

      def modelo = raise(NotImplementedError)
      def chave_parametros = modelo.model_name.singular.to_sym
      def chave_colecao = modelo.model_name.plural.to_sym
      def campos_extras = []
      def filtrar_extra(relacao) = relacao

      def carregar_registro
        @registro = modelo.find(params[:id])
      end

      # A API usa "senha"; o Devise usa "password". Senha em branco no update = não altera.
      def atributos
        dados = params.require(chave_parametros).permit(*CAMPOS, *campos_extras).to_h
        senha = dados.delete("senha")
        dados["password"] = senha if senha.present? || @registro.nil?
        dados
      end
    end
  end
end
