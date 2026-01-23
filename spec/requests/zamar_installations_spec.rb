require 'rails_helper'

RSpec.describe "ZamarInstallations", type: :request do
  let(:user) { create(:user) }
  let(:valid_attributes) do
    {
      name: 'Test ZAMAR Installation',
      installation_type: 'baggage_hall',
      terminal: 'terminal_a',
      identifier: 'ZAMAR-TEST-001'
    }
  end
  let(:invalid_attributes) { { name: '', installation_type: '' } }

  before { login_as(user, scope: :user) }

  describe "GET /index" do
    it "returns http success" do
      create(:zamar_installation)
      get zamar_installations_path
      expect(response).to have_http_status(:success)
    end

    it "filters by terminal" do
      create(:zamar_installation, name: 'Terminal A', terminal: :terminal_a)
      create(:zamar_installation, name: 'Terminal B', terminal: :terminal_b)
      
      get zamar_installations_path, params: { q: { terminal_eq: 'terminal_a' } }
      
      expect(response.body).to include('Terminal A')
    end
  end

  describe "GET /show" do
    let(:installation) { create(:zamar_installation) }

    it "returns http success" do
      get zamar_installation_path(installation)
      expect(response).to have_http_status(:success)
    end

    it "displays terminal name" do
      installation.update(terminal: :terminal_a)
      get zamar_installation_path(installation)
      expect(response.body).to include('A')
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get new_zamar_installation_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new installation" do
        expect {
          post zamar_installations_path, params: { zamar_installation: valid_attributes }
        }.to change(ZamarInstallation, :count).by(1)
      end

      it "redirects to index" do
        post zamar_installations_path, params: { zamar_installation: valid_attributes }
        expect(response).to redirect_to(zamar_installations_path)
      end
    end

    context "with invalid parameters" do
      it "does not create a new installation" do
        expect {
          post zamar_installations_path, params: { zamar_installation: invalid_attributes }
        }.not_to change(ZamarInstallation, :count)
      end

      it "renders new template" do
        post zamar_installations_path, params: { zamar_installation: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /edit" do
    let(:installation) { create(:zamar_installation) }

    it "returns http success" do
      get edit_zamar_installation_path(installation)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /update" do
    let(:installation) { create(:zamar_installation) }
    let(:new_attributes) { { name: 'Updated Name', terminal: 'terminal_b' } }

    context "with valid parameters" do
      it "updates the installation" do
        patch zamar_installation_path(installation), params: { zamar_installation: new_attributes }
        installation.reload
        expect(installation.name).to eq('Updated Name')
        expect(installation.terminal).to eq('terminal_b')
      end

      it "redirects to index" do
        patch zamar_installation_path(installation), params: { zamar_installation: new_attributes }
        expect(response).to redirect_to(zamar_installations_path)
      end
    end

    context "with invalid parameters" do
      it "does not update the installation" do
        patch zamar_installation_path(installation), params: { zamar_installation: { name: '' } }
        installation.reload
        expect(installation.name).not_to eq('')
      end
    end
  end

  describe "DELETE /destroy" do
    let!(:installation) { create(:zamar_installation) }

    context "as admin" do
      let(:admin) { create(:user, :admin) }
      before { login_as(admin, scope: :user) }

      it "destroys the installation" do
        expect {
          delete zamar_installation_path(installation)
        }.to change(ZamarInstallation, :count).by(-1)
      end
    end
  end
end
