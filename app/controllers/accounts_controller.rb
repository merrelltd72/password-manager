class AccountsController < ApplicationController

  # Show all accounts
  def index
    @accounts = Account.all
    render json: @accounts
  end

  # Show an account
  def show
    @account = Account.find_by(id: params[:id])
    render json: @account
  end

  # Create an account
  def create
    @account = Account.create(
      user_id: current_user.id,
      category_id: params[:category_id],
      web_app_name: params[:web_app_name],
      url: params[:url],
      username: params[:username],
      password: params[:password],
      notes: params[:notes]
    )
    render :show
  end

end
