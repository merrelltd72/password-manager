# frozen_string_literal: true

# Controller for managing user accounts, including CRUD operations and bulk upload functionality.
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
      ActivityEvent.create!(
        user: current_user,
        event_type: 'account_created',
        subject_type: 'Account',
        subject_id: account.id,
        metadata: { web_app_name: account.web_app_name }
      )
    else
      render json: { errors: account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @account.update(account_params)
      logger.info "Account #{@account.web_app_name} was updated."
      render json: @account, status: :ok
      ActivityEvent.create!(
        user: current_user,
        event_type: 'account_updated',
        subject_type: 'Account',
        subject_id: @account.id,
        metadata: { web_app_name: @account.web_app_name }
      )
    else
      logger.error "Update of account #{@account.web_app_name} unsuccessful."
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    logger.info 'Account successfully deleted.'
    render json: { message: 'Account successfully deleted!' }
    ActivityEvent.create!(
      user: current_user,
      event_type: 'account_deleted',
      subject_type: 'Account',
      subject_id: @account.id,
      metadata: { web_app_name: @account.web_app_name }
    )
  end

  def upload_accounts
    uploaded_file = params[:file]
    return render json: { error: 'No file uploaded' }, status: :bad_request unless uploaded_file

    format = detect_format(uploaded_file.content_type)
    return render json: { error: 'Unsupported file type' }, status: :unsupported_media_type unless format

    import_run = current_user.import_runs.create!(
      format: format,
      source_filename: uploaded_file.original_filename
    )

    case format
    when 'csv' then import_accounts_from_csv(uploaded_file, import_run)
    when 'xlsx' then import_accounts_from_excel(uploaded_file, import_run)
    when 'json' then import_accounts_from_json(uploaded_file, import_run)
    end
  end

  private

  def detect_format(content_type)
    case content_type
    when 'text/csv'
      'csv'
    when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
       'application/vnd.ms-excel'
      'xlsx'
    when 'application/json'
      'json'
    end
  end

  def import_accounts_from_csv(file, import_run)
    result = import_rows(CSV.foreach(file.path, headers: true).to_a, import_run)

    render json: result[:body], status: result[:status]
  end

  def import_accounts_from_excel(file, import_run)
    spreadsheet = Roo::Spreadsheet.open(file.path)
    rows = spreadsheet.each_with_index.filter_map { |row, i| row unless i.zero? }

    result = import_rows(rows, import_run)

    render json: result[:body], status: result[:status]
  end

  def import_accounts_from_json(file, import_run)
    data = JSON.parse(File.read(file.path))
    rows = data.is_a?(Array) ? data : data.fetch('accounts', [])
    result = import_rows(rows, import_run)
    render json: result[:body], status: result[:status]
  rescue JSON::ParserError => e
    import_run.mark_failed!(e.message)
    render json: { error: 'Invalid JSON file' }, status: :unprocessable_entity
  end

  def import_rows(rows, import_run)
    import_run.mark_processing!
    import_run.update!(total_rows: rows.size)

    succeeded = 0
    failed_rows = []

    rows.each_with_index do |row, index|
      account = build_account_from_row(row)
      if account.save
        succeeded += 1
      else
        failed_rows << { row: index + 2, errors: account.errors.full_messages }
      end
    end

    import_run.update!(
      processed_rows: rows.size,
      succeeded_rows: succeeded,
      failed_rows: failed_rows.size
    )
    import_run.mark_completed!

    ActivityEvent.create!(
      user: current_user,
      event_type: 'import_completed',
      subject_type: 'ImportRun',
      subject_id: import_run.id,
      metadata: { succeeded_rows: succeeded, failed_rows: failed_rows.size }
    )

    import_result(succeeded, failed_rows, import_run.id)
  rescue StandardError => e
    import_run.mark_failed!(e.message)
    { status: :internal_server_error, body: { error: 'Import failed unexpectedly', import_run_id: import_run.id } }
  end

  def build_account_from_row(row)
    attrs = if row.is_a?(Hash)
              row.slice('category_id', 'web_app_name', 'url', 'username', 'password', 'notes')
            else
              row_params(row)
            end
    current_user.accounts.new(attrs)
  end

  def import_result(created_count, errors, import_run_id)
    if errors.empty?
      { status: :ok,
        body: { message: 'Accounts uploaded successfully', created_count: created_count,
                import_run_id: import_run_id } }
    else
      {
        status: :unprocessable_entity,
        body: { message: 'Some accounts could not be uploaded', created_count: created_count, errors: errors,
                import_run_id: import_run_id }
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

  def row_params(row)
    {
      category_id: row[0],
      web_app_name: row[1],
      url: row[2],
      username: row[3],
      password: row[4],
      notes: row[5]
    }
  end
end
