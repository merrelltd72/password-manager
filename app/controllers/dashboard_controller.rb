# frozen_string_literal: true

# Controller to handle dashboard-related actions, such as displaying user-specific data and statistics.
class DashboardController < ApplicationController
  # GET /dashboard#show
  before_action :authenticate_user

  def show
    payload = Dashboard::BuildPayload.new(user: current_user).call
    render json: payload, status: :ok
  end
end
