class ExportsController < ApplicationController
  before_action :authenticate_user!

  def cute_equipments
    @equipments = CuteEquipment.includes(:cute_installation).ordered
    
    respond_to do |format|
      format.xlsx {
        render xlsx: "cute_equipments", 
               filename: "cute_equipment_#{Date.current.strftime('%Y%m%d')}.xlsx"
      }
    end
  end

  def fids_equipments
    @equipments = FidsEquipment.includes(:fids_installation).ordered
    
    respond_to do |format|
      format.xlsx {
        render xlsx: "fids_equipments", 
               filename: "fids_equipment_#{Date.current.strftime('%Y%m%d')}.xlsx"
      }
    end
  end

  def zamar_equipments
    @equipments = ZamarEquipment.includes(:zamar_installation).ordered
    
    respond_to do |format|
      format.xlsx {
        render xlsx: "zamar_equipments", 
               filename: "zamar_equipment_#{Date.current.strftime('%Y%m%d')}.xlsx"
      }
    end
  end

  def cute_installations
    @installations = CuteInstallation.includes(:cute_equipments).ordered
    
    respond_to do |format|
      format.xlsx {
        render xlsx: "cute_installations", 
               filename: "cute_installations_#{Date.current.strftime('%Y%m%d')}.xlsx"
      }
    end
  end

  def fids_installations
    @installations = FidsInstallation.includes(:fids_equipments).ordered
    
    respond_to do |format|
      format.xlsx {
        render xlsx: "fids_installations", 
               filename: "fids_installations_#{Date.current.strftime('%Y%m%d')}.xlsx"
      }
    end
  end

  def zamar_installations
    @installations = ZamarInstallation.includes(:zamar_equipments).ordered
    
    respond_to do |format|
      format.xlsx {
        render xlsx: "zamar_installations", 
               filename: "zamar_installations_#{Date.current.strftime('%Y%m%d')}.xlsx"
      }
    end
  end
end
