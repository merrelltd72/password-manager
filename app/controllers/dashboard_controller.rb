class DashboardController < ApplicationController
  # GET /dashboard#show
  before_action :authenticate_user!
  def show
    payload = Dashboard::BuidPayload.new(user: current_user).call
    render json: payload, status: :ok
  end
end
