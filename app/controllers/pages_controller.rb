class PagesController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    # Statistics will be added later
  end
end
