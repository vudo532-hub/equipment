require 'rails_helper'

RSpec.describe "ZamarEquipments", type: :request do
  let(:user) { create(:user) }
  let(:installation) { create(:zamar_installation) }
  let(:valid_attributes) do
    {
      equipment_type: 'dsm',
      inventory_number: 'ZAMAR-TEST-001',
      serial_number: 'SN-12345',
      status: 'active',
      zamar_installation_id: installation.id
    }
  end
  let(:invalid_attributes) { { equipment_type: '', inventory_number: '' } }

  before { login_as(user, scope: :user) }

  describe "GET /index" do
    it "returns http success" do
      create(:zamar_equipment)
      get zamar_equipments_path
      expect(response).to have_http_status(:success)
    end

    it "filters by status" do
      active = create(:zamar_equipment, status: :active)
      maintenance = create(:zamar_equipment, status: :maintenance)
      
      get zamar_equipments_path, params: { q: { status_eq: 'active' } }
      
      expect(response.body).to include(active.inventory_number)
    end
  end

  describe "GET /show" do
    let(:equipment) { create(:zamar_equipment) }

    it "returns http success" do
      get zamar_equipment_path(equipment)
      expect(response).to have_http_status(:success)
    end

    it "displays audit history section" do
      get zamar_equipment_path(equipment)
      expect(response.body).to include('История изменений')
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get new_zamar_equipment_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates new equipment" do
        expect {
          post zamar_equipments_path, params: { zamar_equipment: valid_attributes }
        }.to change(ZamarEquipment, :count).by(1)
      end

      it "assigns user as creator" do
        post zamar_equipments_path, params: { zamar_equipment: valid_attributes }
        expect(ZamarEquipment.last.user).to eq(user)
      end

      it "assigns user as last_changed_by" do
        post zamar_equipments_path, params: { zamar_equipment: valid_attributes }
        expect(ZamarEquipment.last.last_changed_by).to eq(user)
      end

      it "redirects to index" do
        post zamar_equipments_path, params: { zamar_equipment: valid_attributes }
        expect(response).to redirect_to(zamar_equipments_path)
      end
    end

    context "with invalid parameters" do
      it "does not create equipment" do
        expect {
          post zamar_equipments_path, params: { zamar_equipment: invalid_attributes }
        }.not_to change(ZamarEquipment, :count)
      end

      it "renders new template" do
        post zamar_equipments_path, params: { zamar_equipment: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /edit" do
    let(:equipment) { create(:zamar_equipment) }

    it "returns http success" do
      get edit_zamar_equipment_path(equipment)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /update" do
    let(:equipment) { create(:zamar_equipment) }
    let(:new_attributes) { { status: 'maintenance', note: 'Updated note' } }

    context "with valid parameters" do
      it "updates the equipment" do
        patch zamar_equipment_path(equipment), params: { zamar_equipment: new_attributes }
        equipment.reload
        expect(equipment.status).to eq('maintenance')
        expect(equipment.note).to eq('Updated note')
      end

      it "updates last_changed_by" do
        patch zamar_equipment_path(equipment), params: { zamar_equipment: new_attributes }
        equipment.reload
        expect(equipment.last_changed_by).to eq(user)
      end
    end
  end

  describe "DELETE /destroy" do
    let!(:equipment) { create(:zamar_equipment) }

    context "as admin" do
      let(:admin) { create(:user, :admin) }
      before { login_as(admin, scope: :user) }

      it "destroys the equipment" do
        expect {
          delete zamar_equipment_path(equipment)
        }.to change(ZamarEquipment, :count).by(-1)
      end
    end
  end

  describe "GET /audit_history" do
    let(:equipment) { create(:zamar_equipment) }

    it "returns JSON with audit records" do
      equipment.update(status: :maintenance)
      
      get audit_history_zamar_equipment_path(equipment), as: :json
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('application/json')
      
      json = JSON.parse(response.body)
      expect(json).to have_key('audits')
      expect(json).to have_key('has_more')
    end

    it "paginates results" do
      get audit_history_zamar_equipment_path(equipment), params: { page: 2 }, as: :json
      
      json = JSON.parse(response.body)
      expect(json['page']).to eq(2)
    end
  end
end
