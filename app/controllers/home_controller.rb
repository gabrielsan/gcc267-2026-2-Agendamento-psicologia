class HomeController < ApplicationController
  def index
    redirect_to painel_path if usuario_signed_in?
  end
end
