# frozen_string_literal: true

class ApiTokensController < ApplicationController
  before_action :authenticate_user!

  def index
    @api_tokens = current_user.api_tokens.order(created_at: :desc)
    @new_token = ApiToken.new
  end

  def create
    @api_token = current_user.api_tokens.build(api_token_params)

    if @api_token.save
      # Store token temporarily for display (only shown once)
      flash[:token_created] = @api_token.token
      redirect_to api_tokens_path, notice: 'API токен успешно создан. Скопируйте его сейчас — он больше не будет показан!'
    else
      @api_tokens = current_user.api_tokens.order(created_at: :desc)
      @new_token = @api_token
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @api_token = current_user.api_tokens.find(params[:id])
    @api_token.destroy
    redirect_to api_tokens_path, notice: 'API токен удален'
  end

  private

  def api_token_params
    params.require(:api_token).permit(:name, :expires_at)
  end
end
