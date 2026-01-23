require 'rails_helper'

RSpec.describe "CuteEquipments check_duplicate", type: :request do
  let(:user) { create(:user) }
  let(:installation) { create(:cute_installation) }

  before { login_as(user, scope: :user) }

  describe "POST /cute_equipments/check_duplicate" do
    context "when no duplicate exists" do
      it "returns duplicate: false" do
        post check_duplicate_cute_equipments_path, params: {
          equipment_type: 'keyboard',
          installation_id: installation.id
        }, as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['duplicate']).to be false
      end
    end

    context "when duplicate exists" do
      let!(:existing) do
        create(:cute_equipment, 
               equipment_type: 'keyboard', 
               cute_installation: installation,
               inventory_number: 'INV-EXISTING')
      end

      it "returns duplicate: true with equipment info" do
        post check_duplicate_cute_equipments_path, params: {
          equipment_type: 'keyboard',
          installation_id: installation.id
        }, as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['duplicate']).to be true
        expect(json['equipment']).to be_present
        expect(json['equipment']['inventory_number']).to eq('INV-EXISTING')
      end

      it "excludes equipment by exclude_id" do
        post check_duplicate_cute_equipments_path, params: {
          equipment_type: 'keyboard',
          installation_id: installation.id,
          exclude_id: existing.id
        }, as: :json

        json = JSON.parse(response.body)
        expect(json['duplicate']).to be false
      end
    end

    context "when checking in different installation" do
      let(:other_installation) { create(:cute_installation) }
      let!(:existing) do
        create(:cute_equipment, 
               equipment_type: 'keyboard', 
               cute_installation: installation)
      end

      it "returns duplicate: false" do
        post check_duplicate_cute_equipments_path, params: {
          equipment_type: 'keyboard',
          installation_id: other_installation.id
        }, as: :json

        json = JSON.parse(response.body)
        expect(json['duplicate']).to be false
      end
    end
  end
end
