require 'rails_helper'

RSpec.describe "FidsInstallations", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/fids_installations/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/fids_installations/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/fids_installations/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/fids_installations/edit"
      expect(response).to have_http_status(:success)
    end
  end

end
