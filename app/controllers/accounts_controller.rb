# frozen_string_literal: true

# Accounts functionality
class AccountsController < ApplicationController
  before_action :authenticate_user
  skip_before_action :verify_authenticity_token, only: [:upload_accounts]

  # Show all accounts
  def index
    # @accounts = current_user.accounts.paginate(page: params[:page], per_page: 6)
    accounts = current_user.accounts
    paginate_accounts(accounts)
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
    update_account(@account)
    if @account.valid?
      log.info "Account #{account.web_app_name} was updated."
      render json: { message: 'Account succressfully updated!' }, status: 200
    else
      log.error "Update of account #{account.web_app_name} unsuccessful."
      render json: { errors: @account.errors.full_messages }, status: 422
    end
  end

  def destroy
    @account = current_user.accounts.find_by(id: params[:id])
    @account.destroy
    log.info 'Account successfully deleted.'
    render json: { message: 'Account successfully deleted!' }
  end

  def upload_accounts
    uploaded_file = params[:file]

    # Checking the content type of the file
    if uploaded_file.content_type == 'text/csv'
      process_csv(uploaded_file)
    elsif %w[application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
             application/vnd.ms-excel].include?(uploaded_file.content_type)
      process_excel(uploaded_file)
    else
      render json: { error: 'Invalid file type' }, status: :unprocessable_entity
    end
  end

  private

  def process_csv(file)
    CSV.foreach(file.path, headers: true) do |row|
      pp row
      Account.create(user_id: current_user.id, category_id: row[0], web_app_name: row[1], url: row[2],
                     username: row[3], password: row[4], notes: row[5])
    end
    render json: { message: 'Accounts uploaded successfully' }, status: :ok
  end

  def process_excel(file)
    spreadsheet = Roo::Spreadsheet.open(file.path)
    spreadsheet.each_with_index do |row, index|
      next if index.zero? # Skip header row

      Account.create(user_id: current_user.id, category_id: row[0], web_app_name: row[1], url: row[2],
                     username: row[3], password: row[4], notes: row[5])
    end
  end

  def paginate_accounts(accounts) # rubocop:disable Metrics/MethodLength
    @accounts = accounts.paginate(page: params[:page], per_page: 9)
    render json: {
      data: @accounts,
      meta: {
        current_page: @accounts.current_page,
        next_page: @accounts.next_page,
        prev_page: @accounts.previous_page,
        total_pages: @accounts.total_pages,
        total_count: @accounts.total_entries
      }
    }
  end

  def update_account(account)
    account.assign_attributes(
      category_id: params[:category_id] || @account.category_id,
      web_app_name: params[:web_app_name] || @account.web_app_name,
      url: params[:url] || @account.url,
      username: params[:username] || @account.username,
      password: params[:password] || @account.password,
      notes: params[:notes] || @account.notes
    )
    account.save
  end
end
