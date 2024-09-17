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

  def update
    @account = Account.find_by(id: params[:id])
    @account.update(
      category_id: params[:category_id] || @account.category_id,
      web_app_name: params[:web_app_name] || @account.web_app_name,
      url: params[:url] || @account.url,
      username: params[:username] || @account.username,
      password: params[:password] || @account.password,
      notes: params[:notes] || @account.notes
    )
    if @account.valid?
      render json: {message: "Account succressfully updated!"}, status: 200
    else
      render json: {erros: @account.errors.full_messages }, status: 422
    end
  end

  def destroy
    @account = current_user.account.find_by(id: params[:id])
    @account.destroy
    render json: { message: "Account successfully deleted!" }
  end

end
