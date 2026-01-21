class ExportsController < ApplicationController
  before_action :authenticate_user!

  def cute_equipments
    @equipments = current_user.cute_equipments.includes(:cute_installation).ordered
    
    respond_to do |format|
      format.xlsx {
        render xlsx: "cute_equipments", 
               filename: "cute_equipment_#{Date.current.strftime('%Y%m%d')}.xlsx"
      }
    end
  end

  def fids_equipments
    @equipments = current_user.fids_equipments.includes(:fids_installation).ordered
    
    respond_to do |format|
      format.xlsx {
        render xlsx: "fids_equipments", 
               filename: "fids_equipment_#{Date.current.strftime('%Y%m%d')}.xlsx"
      }
    end
  end

  def cute_installations
    @installations = current_user.cute_installations.includes(:cute_equipments).ordered
    
    respond_to do |format|
      format.xlsx {
        render xlsx: "cute_installations", 
               filename: "cute_installations_#{Date.current.strftime('%Y%m%d')}.xlsx"
      }
    end
  end

  def fids_installations
    @installations = current_user.fids_installations.includes(:fids_equipments).ordered
    
    respond_to do |format|
      format.xlsx {
        render xlsx: "fids_installations", 
               filename: "fids_installations_#{Date.current.strftime('%Y%m%d')}.xlsx"
      }
    end
  end
end
