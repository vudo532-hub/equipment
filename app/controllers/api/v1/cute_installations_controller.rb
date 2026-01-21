# frozen_string_literal: true

module Api
  module V1
    class CuteInstallationsController < Api::BaseController
      before_action :set_installation, only: [:show, :update, :destroy]

      # GET /api/v1/cute_installations
      def index
        @installations = CuteInstallation.includes(:user)
                                          .ransack(params[:q])
                                          .result
                                          .order(created_at: :desc)
                                          .page(params[:page])
                                          .per(params[:per_page] || 25)

        render json: {
          data: @installations.map { |i| serialize_installation(i) },
          meta: pagination_meta(@installations)
        }
      end

      # GET /api/v1/cute_installations/:id
      def show
        render json: { data: serialize_installation(@installation) }
      end

      # POST /api/v1/cute_installations
      def create
        @installation = current_user.cute_installations.build(installation_params)

        if @installation.save
          render_success({ data: serialize_installation(@installation) }, status: :created)
        else
          render_unprocessable(@installation.errors.full_messages)
        end
      end

      # PATCH/PUT /api/v1/cute_installations/:id
      def update
        if @installation.update(installation_params)
          render_success({ data: serialize_installation(@installation) })
        else
          render_unprocessable(@installation.errors.full_messages)
        end
      end

      # DELETE /api/v1/cute_installations/:id
      def destroy
        @installation.destroy
        head :no_content
      end

      private

      def set_installation
        @installation = CuteInstallation.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('CUTE Installation not found')
      end

      def installation_params
        params.require(:cute_installation).permit(
          :name, :code, :location, :description, :status
        )
      end

      def serialize_installation(installation)
        {
          id: installation.id,
          name: installation.name,
          code: installation.code,
          location: installation.location,
          description: installation.description,
          status: installation.status,
          created_at: installation.created_at.iso8601,
          updated_at: installation.updated_at.iso8601,
          user_id: installation.user_id
        }
      end
    end
  end
end
