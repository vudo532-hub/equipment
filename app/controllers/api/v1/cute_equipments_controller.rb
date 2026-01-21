# frozen_string_literal: true

module Api
  module V1
    class CuteEquipmentsController < Api::BaseController
      before_action :set_equipment, only: [:show, :update, :destroy]

      # GET /api/v1/cute_equipments
      def index
        @equipments = CuteEquipment.includes(:user, :cute_installation)
                                    .ransack(params[:q])
                                    .result
                                    .order(created_at: :desc)
                                    .page(params[:page])
                                    .per(params[:per_page] || 25)

        render json: {
          data: @equipments.map { |e| serialize_equipment(e) },
          meta: pagination_meta(@equipments)
        }
      end

      # GET /api/v1/cute_equipments/:id
      def show
        render json: { data: serialize_equipment(@equipment) }
      end

      # POST /api/v1/cute_equipments
      def create
        @equipment = current_user.cute_equipments.build(equipment_params)

        if @equipment.save
          render_success({ data: serialize_equipment(@equipment) }, status: :created)
        else
          render_unprocessable(@equipment.errors.full_messages)
        end
      end

      # PATCH/PUT /api/v1/cute_equipments/:id
      def update
        if @equipment.update(equipment_params)
          render_success({ data: serialize_equipment(@equipment) })
        else
          render_unprocessable(@equipment.errors.full_messages)
        end
      end

      # DELETE /api/v1/cute_equipments/:id
      def destroy
        @equipment.destroy
        head :no_content
      end

      private

      def set_equipment
        @equipment = CuteEquipment.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('CUTE Equipment not found')
      end

      def equipment_params
        params.require(:cute_equipment).permit(
          :name, :serial_number, :model, :manufacturer, :status, 
          :description, :cute_installation_id, :installation_date
        )
      end

      def serialize_equipment(equipment)
        {
          id: equipment.id,
          name: equipment.name,
          serial_number: equipment.serial_number,
          model: equipment.model,
          manufacturer: equipment.manufacturer,
          status: equipment.status,
          description: equipment.description,
          installation_date: equipment.installation_date&.iso8601,
          cute_installation_id: equipment.cute_installation_id,
          cute_installation_name: equipment.cute_installation&.name,
          created_at: equipment.created_at.iso8601,
          updated_at: equipment.updated_at.iso8601,
          user_id: equipment.user_id
        }
      end
    end
  end
end
