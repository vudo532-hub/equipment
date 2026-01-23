class PagesController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    # CUTE Statistics
    @cute_equipments_count = CuteEquipment.count
    @cute_active_count = CuteEquipment.where(status: "active").count
    @cute_maintenance_count = CuteEquipment.where(status: "maintenance").count
    @cute_installations_count = CuteInstallation.count
    
    # FIDS Statistics
    @fids_equipments_count = FidsEquipment.count
    @fids_active_count = FidsEquipment.where(status: "active").count
    @fids_maintenance_count = FidsEquipment.where(status: "maintenance").count
    @fids_installations_count = FidsInstallation.count
    
    # ZAMAR Statistics
    @zamar_equipments_count = ZamarEquipment.count
    @zamar_active_count = ZamarEquipment.where(status: "active").count
    @zamar_maintenance_count = ZamarEquipment.where(status: "maintenance").count
    @zamar_installations_count = ZamarInstallation.count
    
    # Total Statistics
    @total_equipments_count = @cute_equipments_count + @fids_equipments_count + @zamar_equipments_count
    @total_installations_count = @cute_installations_count + @fids_installations_count + @zamar_installations_count
    
    # Recent equipment from all systems
    cute_recent = CuteEquipment.includes(:cute_installation).order(created_at: :desc).limit(5).map do |e|
      { equipment: e, system: "CUTE", color: "blue", path: cute_equipment_path(e) }
    end
    
    fids_recent = FidsEquipment.includes(:fids_installation).order(created_at: :desc).limit(5).map do |e|
      { equipment: e, system: "FIDS", color: "green", path: fids_equipment_path(e) }
    end
    
    zamar_recent = ZamarEquipment.includes(:zamar_installation).order(created_at: :desc).limit(5).map do |e|
      { equipment: e, system: "ZAMAR", color: "purple", path: zamar_equipment_path(e) }
    end
    
    @recent_equipments = (cute_recent + fids_recent + zamar_recent)
      .sort_by { |e| e[:equipment].created_at }
      .reverse
      .first(5)
  end
end
