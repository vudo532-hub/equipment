# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::CuteEquipments', type: :request do
  let(:user) { create(:user) }
  let(:api_token) { create(:api_token, user: user) }
  let(:headers) { { 'Authorization' => "Bearer #{api_token.token}" } }
  let(:installation) { create(:cute_installation, user: user) }

  describe 'GET /api/v1/cute_equipments' do
    before do
      create_list(:cute_equipment, 3, user: user, cute_installation: installation)
    end

    context 'with valid token' do
      it 'returns list of equipments' do
        get '/api/v1/cute_equipments', headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data'].length).to eq(3)
        expect(json['meta']).to include('current_page', 'total_pages', 'total_count')
      end

      it 'supports pagination' do
        get '/api/v1/cute_equipments', headers: headers, params: { page: 1, per_page: 2 }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data'].length).to eq(2)
        expect(json['meta']['per_page']).to eq(2)
      end

      it 'supports Ransack filtering' do
        equipment = create(:cute_equipment, user: user, equipment_type: 'Special Printer')
        get '/api/v1/cute_equipments', headers: headers, params: { q: { equipment_type_cont: 'Special' } }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data'].length).to eq(1)
        expect(json['data'].first['equipment_type']).to eq('Special Printer')
      end
    end

    context 'without token' do
      it 'returns unauthorized' do
        get '/api/v1/cute_equipments'

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Token missing')
      end
    end

    context 'with expired token' do
      let(:expired_token) { create(:api_token, :expired, user: user) }

      it 'returns unauthorized' do
        get '/api/v1/cute_equipments', headers: { 'Authorization' => "Bearer #{expired_token.token}" }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Invalid or expired token')
      end
    end
  end

  describe 'GET /api/v1/cute_equipments/:id' do
    let(:equipment) { create(:cute_equipment, user: user, cute_installation: installation) }

    context 'with valid token' do
      it 'returns the equipment' do
        get "/api/v1/cute_equipments/#{equipment.id}", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['id']).to eq(equipment.id)
        expect(json['data']['inventory_number']).to eq(equipment.inventory_number)
      end
    end

    context 'with non-existent id' do
      it 'returns not found' do
        get '/api/v1/cute_equipments/999999', headers: headers

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('CUTE Equipment not found')
      end
    end
  end

  describe 'POST /api/v1/cute_equipments' do
    let(:valid_params) do
      {
        cute_equipment: {
          equipment_type: 'Printer',
          equipment_model: 'HP LaserJet',
          inventory_number: 'NEW-001',
          serial_number: 'SN12345',
          status: 'active',
          cute_installation_id: installation.id
        }
      }
    end

    context 'with valid params' do
      it 'creates equipment' do
        expect {
          post '/api/v1/cute_equipments', headers: headers, params: valid_params
        }.to change(CuteEquipment, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['data']['equipment_type']).to eq('Printer')
        expect(json['data']['user_id']).to eq(user.id)
      end
    end

    context 'with invalid params' do
      it 'returns unprocessable entity' do
        post '/api/v1/cute_equipments', headers: headers, params: { cute_equipment: { equipment_type: '' } }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
  end

  describe 'PATCH /api/v1/cute_equipments/:id' do
    let(:equipment) { create(:cute_equipment, user: user, cute_installation: installation) }

    context 'with valid params' do
      it 'updates equipment' do
        patch "/api/v1/cute_equipments/#{equipment.id}", 
              headers: headers, 
              params: { cute_equipment: { equipment_type: 'Updated Type' } }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data']['equipment_type']).to eq('Updated Type')
      end
    end

    context 'with invalid params' do
      it 'returns unprocessable entity' do
        patch "/api/v1/cute_equipments/#{equipment.id}", 
              headers: headers, 
              params: { cute_equipment: { equipment_type: '' } }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /api/v1/cute_equipments/:id' do
    let!(:equipment) { create(:cute_equipment, user: user, cute_installation: installation) }

    it 'deletes equipment' do
      expect {
        delete "/api/v1/cute_equipments/#{equipment.id}", headers: headers
      }.to change(CuteEquipment, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'token usage tracking' do
    it 'updates last_used_at on successful request' do
      expect(api_token.last_used_at).to be_nil

      get '/api/v1/cute_equipments', headers: headers

      api_token.reload
      expect(api_token.last_used_at).to be_present
    end
  end
end
