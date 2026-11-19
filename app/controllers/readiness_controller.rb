class ReadinessController < ActionController::API
  def show
    ActiveRecord::Base.connection.execute("SELECT 1")
    render json: { service: "agendamento", database: "ok" }
  end
end
