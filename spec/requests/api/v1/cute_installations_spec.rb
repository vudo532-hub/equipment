# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::CuteInstallations', type: :request do
  let(:user) { create(:user) }
  let(:api_token) { create(:api_token, user: user) }
  let(:headers) { { 'Authorization' => "Bearer #{api_token.token}" } }

  describe 'GET /api/v1/cute_installations' do
    before do
      create_list(:cute_installation, 3, user: user)
    end

    context 'with valid token' do
      it 'returns list of installations' do
        get '/api/v1/cute_installations', headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['data'].length).to eq(3)
      end
    end

    context 'without token' do
      it 'returns unauthorized' do
        get '/api/v1/cute_installations'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /api/v1/cute_installations/:id' do
    let(:installation) { create(:cute_installation, user: user) }

    it 'returns the installation' do
      get "/api/v1/cute_installations/#{installation.id}", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['id']).to eq(installation.id)
    end
  end

  describe 'POST /api/v1/cute_installations' do
    let(:valid_params) do
      {
        cute_installation: {
          name: 'New Terminal',
          installation_type: 'Gate',
          identifier: 'GATE-001'
        }
      }
    end

    it 'creates installation' do
      expect {
        post '/api/v1/cute_installations', headers: headers, params: valid_params
      }.to change(CuteInstallation, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe 'PATCH /api/v1/cute_installations/:id' do
    let(:installation) { create(:cute_installation, user: user) }

    it 'updates installation' do
      patch "/api/v1/cute_installations/#{installation.id}", 
            headers: headers, 
            params: { cute_installation: { name: 'Updated Name' } }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['name']).to eq('Updated Name')
    end
  end

  describe 'DELETE /api/v1/cute_installations/:id' do
    let!(:installation) { create(:cute_installation, user: user) }

    it 'deletes installation' do
      expect {
        delete "/api/v1/cute_installations/#{installation.id}", headers: headers
      }.to change(CuteInstallation, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
