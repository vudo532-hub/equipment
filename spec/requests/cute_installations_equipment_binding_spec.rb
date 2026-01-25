# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CuteInstallations Equipment Binding', type: :request do
  let(:user) { create(:user, :editor) }
  let(:admin) { create(:user, :admin) }
  let(:installation) { create(:cute_installation) }

  before { login_as(user, scope: :user) }

  describe 'POST /cute_installations/:id/search_equipment' do
    let!(:warehouse_eq) { create(:cute_equipment, :without_installation, status: :active, serial_number: 'FIND-123') }
    let!(:assigned_eq) { create(:cute_equipment, cute_installation: installation, serial_number: 'ASSIGNED-456') }

    it 'finds equipment by serial number' do
      post search_equipment_cute_installation_path(installation), params: { serial_number: 'FIND-123' }, as: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['equipment']).to be_present
      expect(json['equipment']['serial_number']).to eq('FIND-123')
    end

    it 'returns not_found when equipment not found' do
      post search_equipment_cute_installation_path(installation), params: { serial_number: 'NOTFOUND' }, as: :json

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to be_present
    end

    it 'returns not_found when equipment is already assigned' do
      post search_equipment_cute_installation_path(installation), params: { serial_number: 'ASSIGNED-456' }, as: :json

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json['error']).to include('уже привязано')
    end
  end

  describe 'POST /cute_installations/:id/attach_equipment' do
    let!(:equipment) { create(:cute_equipment, :without_installation, status: :active, equipment_type: 'keyboard') }

    it 'attaches equipment to installation' do
      post attach_equipment_cute_installation_path(installation), params: { equipment_id: equipment.id }, as: :json

      expect(response).to have_http_status(:success)
      equipment.reload
      expect(equipment.cute_installation).to eq(installation)
    end

    it 'changes equipment status to active' do
      equipment.update(status: :ready_to_dispatch)

      post attach_equipment_cute_installation_path(installation), params: { equipment_id: equipment.id }, as: :json

      equipment.reload
      expect(equipment.status).to eq('active')
    end

    context 'when duplicate type exists for non-admin' do
      let!(:existing_eq) { create(:cute_equipment, equipment_type: 'keyboard', cute_installation: installation) }

      it 'returns unprocessable_entity status with error' do
        post attach_equipment_cute_installation_path(installation), params: { equipment_id: equipment.id }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['error']).to include('Дублирование типов')
      end
    end

    context 'when admin allows duplicate type' do
      let!(:existing_eq) { create(:cute_equipment, equipment_type: 'keyboard', cute_installation: installation) }

      it 'attaches equipment successfully' do
        # Выходим из сессии обычного пользователя и входим как admin
        logout(:user)
        login_as(admin, scope: :user)

        post attach_equipment_cute_installation_path(installation), params: { equipment_id: equipment.id }, as: :json

        # Администратор может добавлять дубликаты
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
      end
    end
  end

  describe 'DELETE /cute_installations/:id/detach_equipment' do
    let!(:equipment) { create(:cute_equipment, cute_installation: installation, status: :active) }

    it 'detaches equipment from installation' do
      delete detach_equipment_cute_installation_path(installation), params: { equipment_id: equipment.id }, as: :json

      expect(response).to have_http_status(:success)
      equipment.reload
      expect(equipment.cute_installation).to be_nil
    end

    it 'changes equipment status to ready_to_dispatch' do
      delete detach_equipment_cute_installation_path(installation), params: { equipment_id: equipment.id }, as: :json

      equipment.reload
      expect(equipment.status).to eq('ready_to_dispatch')
    end
  end
end
