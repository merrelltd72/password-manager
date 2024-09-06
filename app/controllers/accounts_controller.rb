class AccountsController < ApplicationController
  before_action :authenticate_user

  # Show all accounts
  def index
    @accounts = current_user.accounts
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

  def destroy
    @account = current_user.account.find_by(id: params[:id])
    @account.destroy
    render json: { message: "Account successfully deleted!" }
  end

end
