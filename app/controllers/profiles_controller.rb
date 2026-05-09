# frozen_string_literal: true

# Controller for user profile management, including viewing and updating profile information and changing password.
class ProfilesController < ApplicationController
  before_action :authenticate_user

  def show
    pref = current_user.user_preference || current_user.build_user_preference

    render json: {
      identity: {
        user_id: current_user.id,
        username: current_user.username,
        email: current_user.email,
        member_since: current_user.created_at.iso8601
      },
      preferences: {
        timezone: pref.timezone || 'UTC',
        date_format: pref.date_format || 'MMM d, yyyy',
        generator_defaults: pref.generator_defaults.presence || {
          length: 16, symbols: true, numbers: true, uppercase: true
        },
        reminder_defaults: pref.reminder_defaults.presence || {
          lead_days: 7, repeat: 'none'
        }
      },
      security: {
        has_2fa: false,
        active_sessions_supported: false
      },
      data_controls: {
        last_import_at: nil,
        last_export_at: nil
      }
    }, status: :ok
  end

  def update
    ok = Profile::Update.new(user: current_user, params: profile_update_params.to_h.deep_symbolize_keys).call

    if ok
      show
    else
      render json: { errors: combined_errors }, status: :unprocessable_entity
    end
  end

  def update_password
    unless current_user.authenticate(password_params[:current_password])
      return render json: { errors: ['Current password is incorrect'] }, status: :unprocessable_entity
    end

    if current_user.update(
      password: password_params[:new_password],
      password_confirmation: password_params[:new_password_confirmation]
    )
      jwt = issue_jwt(current_user.id)
      cookies.signed[:jwt] = { value: jwt, httponly: true }
      render json: { message: 'Password updated successfully' }, status: :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def profile_update_params
    params.permit(
      :username,
      preferences: [
        :timezone,
        :date_format,
        { generator_defaults: %i[length symbols numbers uppercase] },
        { reminder_defaults: %i[lead_days repeat] }
      ]
    )
  end

  def password_params
    params.permit(:current_password, :new_password, :new_password_confirmation)
  end

  def combined_errors
    errors = []
    errors.concat(current_user.errors.full_messages)
    errors.concat(current_user.user_preference&.errors&.full_messages || [])
    errors.uniq
  end

  def issue_jwt(user_id)
    JWT.encode(
      { user_id: user_id, exp: 24.hours.from_now.to_i },
      jwt_secret_key,
      'HS256'
    )
  end
end
