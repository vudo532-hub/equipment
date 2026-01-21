require 'rails_helper'

RSpec.describe "FidsInstallations", type: :request do
  let(:user) { create(:user) }
  let(:installation) { create(:fids_installation, user: user) }

  before { login_as(user, scope: :user) }

  describe "GET /index" do
    it "returns http success" do
      get fids_installations_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get fids_installation_path(installation)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get new_fids_installation_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get edit_fids_installation_path(installation)
      expect(response).to have_http_status(:success)
    end
  end
end
