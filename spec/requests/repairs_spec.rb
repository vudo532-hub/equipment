# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Repairs', type: :request do
  let(:user) { create(:user, :editor) }
  let(:admin) { create(:user, :admin) }

  before { login_as(user, scope: :user) }

  describe 'GET /repairs' do
    it 'returns successful response' do
      get repairs_path
      expect(response).to have_http_status(:success)
    end

    it 'displays equipment in maintenance status' do
      maintenance_eq = create(:cute_equipment, :maintenance)
      active_eq = create(:cute_equipment, status: :active)

      get repairs_path

      expect(response.body).to include(maintenance_eq.serial_number)
      expect(response.body).not_to include(active_eq.serial_number)
    end

    it 'aggregates equipment from all systems' do
      cute_eq = create(:cute_equipment, :maintenance)
      fids_eq = create(:fids_equipment, status: :maintenance)
      zamar_eq = create(:zamar_equipment, status: :maintenance)

      get repairs_path

      expect(response.body).to include(cute_eq.serial_number)
      expect(response.body).to include(fids_eq.serial_number)
      expect(response.body).to include(zamar_eq.serial_number)
    end
  end

  describe 'POST /repairs/create_batch' do
    context 'with valid equipment' do
      let!(:equipment1) { create(:cute_equipment, :maintenance) }
      let!(:equipment2) { create(:fids_equipment, status: :maintenance) }

      it 'creates a repair batch' do
        expect {
          post create_batch_repairs_path, params: {
            equipment_ids: [
              { type: 'CuteEquipment', id: equipment1.id },
              { type: 'FidsEquipment', id: equipment2.id }
            ]
          }, as: :json
        }.to change(RepairBatch, :count).by(1)
      end

      it 'creates repair batch items' do
        expect {
          post create_batch_repairs_path, params: {
            equipment_ids: [
              { type: 'CuteEquipment', id: equipment1.id },
              { type: 'FidsEquipment', id: equipment2.id }
            ]
          }, as: :json
        }.to change(RepairBatchItem, :count).by(2)
      end

      it 'changes equipment status to waiting_repair' do
        post create_batch_repairs_path, params: {
          equipment_ids: [
            { type: 'CuteEquipment', id: equipment1.id }
          ]
        }, as: :json

        equipment1.reload
        expect(equipment1.status).to eq('waiting_repair')
      end

      it 'returns success response' do
        post create_batch_repairs_path, params: {
          equipment_ids: [
            { type: 'CuteEquipment', id: equipment1.id }
          ]
        }, as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['repair_number']).to match(/^REP-\d{4}-\d{3}$/)
      end
    end

    context 'without equipment' do
      it 'returns error' do
        post create_batch_repairs_path, params: { equipment_ids: [] }, as: :json

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Не выбрано оборудование')
      end
    end
  end

  describe 'GET /repairs/:id' do
    let(:batch) { RepairBatch.create!(user: user, status: 'sent') }
    let!(:item) { 
      equipment = create(:cute_equipment, :maintenance)
      RepairBatchItem.create!(
        repair_batch: batch,
        equipment_type: 'CuteEquipment',
        equipment_id: equipment.id,
        system: 'CUTE',
        serial_number: equipment.serial_number
      )
    }

    it 'returns successful response' do
      get repair_path(batch)
      expect(response).to have_http_status(:success)
    end

    it 'displays batch details' do
      get repair_path(batch)

      expect(response.body).to include(batch.repair_number)
      expect(response.body).to include(item.serial_number)
    end
  end

  describe 'GET /repairs/history' do
    it 'returns successful response' do
      get history_repairs_path
      expect(response).to have_http_status(:success)
    end

    it 'displays repair batches' do
      batch = RepairBatch.create!(user: user, status: 'sent')
      equipment = create(:cute_equipment, :maintenance)
      RepairBatchItem.create!(
        repair_batch: batch,
        equipment_type: 'CuteEquipment',
        equipment_id: equipment.id,
        system: 'CUTE',
        serial_number: equipment.serial_number
      )

      get history_repairs_path

      expect(response.body).to include(batch.repair_number)
    end
  end

  describe 'GET /repairs/:id/export_to_excel' do
    let(:batch) { RepairBatch.create!(user: user, status: 'sent') }
    let!(:item) { 
      equipment = create(:cute_equipment, :maintenance)
      RepairBatchItem.create!(
        repair_batch: batch,
        equipment_type: 'CuteEquipment',
        equipment_id: equipment.id,
        system: 'CUTE',
        serial_number: equipment.serial_number
      )
    }

    it 'returns Excel file' do
      get export_to_excel_repair_path(batch, format: :xlsx)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('spreadsheet')
    end
  end
end
