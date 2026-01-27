module Repairs
  class ActsController < ApplicationController
    before_action :authenticate_user!

    def index
      @q = RepairBatch.includes(:user, :repair_batch_items).ransack(params[:q])
      @batches = @q.result(distinct: true).order(created_at: :desc)

      # Пагинация
      @pagy, @batches = pagy(@batches, items: 20)

      # Статистика
      @total_batches = RepairBatch.count
      @total_equipment = RepairBatch.sum(:equipment_count)
      @batches_this_month = RepairBatch.where('created_at >= ?', Time.current.beginning_of_month).count
    end

    def show
      @batch = RepairBatch.includes(:repair_batch_items, :user).find(params[:id])
      @items = @batch.repair_batch_items.order(:system, :model)
    end

    def export_to_excel
      @batch = RepairBatch.includes(:repair_batch_items, :user).find(params[:id])
      
      respond_to do |format|
        format.xlsx {
          # Создаем новый Excel файл
          stringio = StringIO.new
          workbook = WriteXLSX.new(stringio)
          worksheet = workbook.add_worksheet("Акт ремонта #{@batch.repair_number}")
          
          # Стили
          header_format = workbook.add_format(
            bold: true,
            bg_color: '#f3f4f6',
            border: 1,
            align: 'center',
            valign: 'vcenter'
          )
          cell_format = workbook.add_format(
            border: 1,
            align: 'left',
            valign: 'vcenter'
          )
          title_format = workbook.add_format(
            bold: true,
            size: 16,
            align: 'center'
          )
          
          # Заголовок
          worksheet.merge_range('A1:F1', "Акт передачи в ремонт №#{@batch.repair_number}", title_format)
          worksheet.set_row(0, 30)
          
          # Информация об акте
          worksheet.write('A3', 'Номер акта:', header_format)
          worksheet.write('B3', @batch.repair_number, cell_format)
          worksheet.write('A4', 'Дата создания:', header_format)
          worksheet.write('B4', l(@batch.created_at, format: :long), cell_format)
          worksheet.write('A5', 'Создал:', header_format)
          worksheet.write('B5', @batch.user&.full_name || "—", cell_format)
          worksheet.write('A6', 'Статус:', header_format)
          worksheet.write('B6', @batch.status_text, cell_format)
          worksheet.write('A7', 'Количество оборудования:', header_format)
          worksheet.write('B7', "#{@batch.equipment_count} ед.", cell_format)
          
          # Заголовки таблицы
          headers = ['№', 'Тип', 'Модель', 'Инв. №', 'Сер. №', 'Номер заявки']
          headers.each_with_index do |header, index|
            worksheet.write(9, index, header, header_format)
          end
          
          # Данные оборудования
          @batch.repair_batch_items.each_with_index do |item, index|
            worksheet.write(10 + index, 0, index + 1, cell_format)
            worksheet.write(10 + index, 1, item.equipment_type_display, cell_format)
            worksheet.write(10 + index, 2, item.model || "—", cell_format)
            worksheet.write(10 + index, 3, item.inventory_number, cell_format)
            worksheet.write(10 + index, 4, item.serial_number || "—", cell_format)
            worksheet.write(10 + index, 5, item.repair_ticket_number || "—", cell_format)
          end
          
          # Устанавливаем ширину колонок
          worksheet.set_column('A:A', 5)  # №
          worksheet.set_column('B:B', 10) # Тип
          worksheet.set_column('C:C', 20) # Модель
          worksheet.set_column('D:D', 15) # Инв. №
          worksheet.set_column('E:E', 15) # Сер. №
          worksheet.set_column('F:F', 15) # Номер заявки
          
          # Отправляем файл
          workbook.close
          send_data stringio.string, 
                    filename: "Акт_ремонта_#{@batch.repair_number}.xlsx",
                    type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        }
      end
    end
  end
end
