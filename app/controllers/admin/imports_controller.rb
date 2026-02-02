# frozen_string_literal: true

module Admin
  class ImportsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    def new
      @systems = [["CUTE", "cute"], ["FIDS", "fids"], ["ZAMAR", "zamar"]]
    end

    def create
      file = params[:import_file]
      system = params[:system]

      if file.blank?
        redirect_to new_admin_import_path, alert: "Выберите файл для импорта"
        return
      end

      unless %w[cute fids zamar].include?(system)
        redirect_to new_admin_import_path, alert: "Выберите корректную систему"
        return
      end

      result = EquipmentImportService.new(file, system).import

      if result[:success]
        # Логируем импорт
        Audited.audit_class.create!(
          auditable_type: "Import",
          action: "create",
          user: current_user,
          audited_changes: {
            system: system,
            imported: result[:imported],
            skipped: result[:skipped]
          },
          comment: "Импорт оборудования из файла"
        )

        flash[:notice] = "Импорт завершён. Импортировано: #{result[:imported]}, Пропущено: #{result[:skipped]}"
        if result[:errors].any?
          flash[:alert] = "Ошибки: #{result[:errors].join('; ')}"
        end
        redirect_to new_admin_import_path
      else
        redirect_to new_admin_import_path, alert: result[:error]
      end
    end

    def template
      csv_content = generate_csv_template

      send_data csv_content,
                filename: "equipment_import_template.csv",
                type: "text/csv; charset=utf-8"
    end

    private

    def require_admin!
      unless current_user.admin?
        redirect_to root_path, alert: "Доступ запрещён. Требуются права администратора."
      end
    end

    def generate_csv_template
      CSV.generate(col_sep: ";", encoding: "UTF-8") do |csv|
        csv << [
          "Тип оборудования",
          "Модель",
          "Инвентарный номер",
          "Серийный номер",
          "Терминал",
          "Тип места установки",
          "Название места",
          "Статус",
          "Примечание"
        ]
        csv << [
          "Сканер",
          "HP ScanJet Pro 3500",
          "INV-001",
          "SN12345678",
          "A",
          "Стойка регистрации",
          "Стойка 1",
          "В работе",
          "Установлен 01.02.2026"
        ]
        csv << [
          "Принтер посадочных талонов",
          "Epson TM-T88VI",
          "INV-002",
          "SN87654321",
          "B",
          "Выход на посадку",
          "Гейт B12",
          "В работе",
          ""
        ]
      end
    end
  end
end
