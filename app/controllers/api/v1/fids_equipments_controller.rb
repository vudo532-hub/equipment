# frozen_string_literal: true

module Api
  module V1
    class FidsEquipmentsController < Api::BaseController
      before_action :set_equipment, only: [:show, :update, :destroy]

      # GET /api/v1/fids_equipments
      def index
        @equipments = FidsEquipment.includes(:user, :fids_installation)
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

      # GET /api/v1/fids_equipments/:id
      def show
        render json: { data: serialize_equipment(@equipment) }
      end

      # POST /api/v1/fids_equipments
      def create
        @equipment = current_user.fids_equipments.build(equipment_params)

        if @equipment.save
          render_success({ data: serialize_equipment(@equipment) }, status: :created)
        else
          render_unprocessable(@equipment.errors.full_messages)
        end
      end

      # PATCH/PUT /api/v1/fids_equipments/:id
      def update
        if @equipment.update(equipment_params)
          render_success({ data: serialize_equipment(@equipment) })
        else
          render_unprocessable(@equipment.errors.full_messages)
        end
      end

      # DELETE /api/v1/fids_equipments/:id
      def destroy
        @equipment.destroy
        head :no_content
      end

      private

      def set_equipment
        @equipment = FidsEquipment.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render_not_found('FIDS Equipment not found')
      end

      def equipment_params
        params.require(:fids_equipment).permit(
          :name, :serial_number, :model, :manufacturer, :status, 
          :description, :fids_installation_id, :installation_date
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
          fids_installation_id: equipment.fids_installation_id,
          fids_installation_name: equipment.fids_installation&.name,
          created_at: equipment.created_at.iso8601,
          updated_at: equipment.updated_at.iso8601,
          user_id: equipment.user_id
        }
      end
    end
  end
end
