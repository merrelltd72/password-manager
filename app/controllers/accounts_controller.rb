# frozen_string_literal: true

# Accounts functionality
class AccountsController < ApplicationController
  before_action :authenticate_user
  before_action :set_account, only: %i[show update destroy]

  # Show all accounts
  def index
    accounts = current_user.accounts
    paginate_accounts(accounts)
  end

  # Show an account
  def show
    render json: @account
  end

  # Create an account
  def create
    account = current_user.accounts.new(account_params)

    if account.save
      render json: account, status: :created
    else
      render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @account.update(account_params)
      logger.info "Account #{@account.web_app_name} was updated."
      render json: @account, status: :ok
    else
      logger.error "Update of account #{@account.web_app_name} unsuccessful."
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    logger.info 'Account successfully deleted.'
    render json: { message: 'Account successfully deleted!' }
  end

  def upload_accounts
    uploaded_file = params[:file]
    return render json: { error: 'No file uploaded' }, status: :bad_request unless uploaded_file

    # Checking the content type of the file
    case uploaded_file.content_type
    when 'text/csv'
      import_accounts_from_csv(uploaded_file)
    when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-excel'
      import_accounts_from_excel(uploaded_file)
    else
      render json: { error: 'Unsupported file type' }, status: :unsupported_media_type
    end
  end

  private

  def import_accounts_from_csv(file)
    result = import_rows(CSV.foreach(file.path, headers: true).to_a)

    render json: result[:body], status: result[:status]
  end

  def import_accounts_from_excel(file)
    spreadsheet = Roo::Spreadsheet.open(file.path)
    rows = []

    spreadsheet.each_with_index do |row, index|
      next if index.zero?

      rows << row
    end

    result = import_rows(rows)

    render json: result[:body], status: result[:status]
  end

  def import_rows(rows)
    created_count = 0
    errors = []

    rows.each_with_index do |row, index|
      account = build_account_from_row(row)
      if account.save
        created_count += 1
      else
        errors << { row: index + 2, errors: account.errors.full_messages }
      end
    end

    import_result(created_count, errors)
  end

  def build_account_from_row(row)
    current_user.accounts.new(
      category_id: row[0],
      web_app_name: row[1],
      url: row[2],
      username: row[3],
      password: row[4],
      notes: row[5]
    )
  end

  def import_result(created_count, errors)
    if errors.empty?
      { status: :ok, body: { message: 'Accounts uploaded successfully', create_count: created_count } }
    else
      {
        status: :unprocessable_entity,
        body: { message: 'Some accounts could not be uploaded', created_count: created_count, errors: errors }
      }
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

  def set_account
    @account = current_user.accounts.find_by(id: params[:id])
    render json: { error: 'Account not found' }, status: :not_found unless @account
  end

  def account_params
    params.permit(:category_id, :web_app_name, :url, :username, :password, :notes)
  end
end
