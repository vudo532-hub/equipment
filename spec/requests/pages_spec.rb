require 'rails_helper'

RSpec.describe "Pages", type: :request do
  let(:user) { create(:user) }

  before { login_as(user, scope: :user) }

  describe "GET /dashboard" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end
end
