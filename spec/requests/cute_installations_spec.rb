require 'rails_helper'

RSpec.describe "CuteInstallations", type: :request do
  let(:user) { create(:user) }
  let(:installation) { create(:cute_installation, user: user) }

  before { login_as(user, scope: :user) }

  describe "GET /index" do
    it "returns http success" do
      get cute_installations_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get cute_installation_path(installation)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get new_cute_installation_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get edit_cute_installation_path(installation)
      expect(response).to have_http_status(:success)
    end
  end
end
