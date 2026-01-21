# frozen_string_literal: true

module Api
  class BaseController < ActionController::API
    before_action :authenticate_with_token!

    attr_reader :current_user, :current_api_token

    private

    def authenticate_with_token!
      token = extract_token_from_header
      return render_unauthorized('Token missing') unless token

      api_token = ApiToken.active.find_by(token: token)
      return render_unauthorized('Invalid or expired token') unless api_token

      api_token.touch_last_used!
      @current_api_token = api_token
      @current_user = api_token.user
    end

    def extract_token_from_header
      auth_header = request.headers['Authorization']
      return nil unless auth_header

      # Support "Bearer TOKEN" or just "TOKEN"
      if auth_header.start_with?('Bearer ')
        auth_header.split(' ').last
      else
        auth_header
      end
    end

    def render_unauthorized(message = 'Unauthorized')
      render json: { error: message }, status: :unauthorized
    end

    def render_not_found(message = 'Not found')
      render json: { error: message }, status: :not_found
    end

    def render_unprocessable(errors)
      render json: { errors: errors }, status: :unprocessable_entity
    end

    def render_success(data, status: :ok)
      render json: data, status: status
    end

    # Pagination helper
    def pagination_meta(collection)
      {
        current_page: collection.current_page,
        total_pages: collection.total_pages,
        total_count: collection.total_count,
        per_page: collection.limit_value
      }
    end
  end
end
