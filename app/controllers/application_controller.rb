# frozen_string_literal: true

# Configuration for ActionController
class ApplicationController < ActionController::Base
  # protect_from_forgery with: :exception, unless: -> { request.format.json? }
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  def current_user
    token = cookies.signed[:jwt]
    return unless token

    begin
      find_user(token)
    rescue JWT::ExpiredSignature, JWT::DecodeError
      nil
    end
  end

  def authenticate_user
    return if current_user

    render json: { error: 'Unauthorized' }, status: :unauthorized
  end

  private

  def generate_jwt_token(token)
    JWT.decode(
      token,
      jwt_secret_key,
      true,
      { algorithm: 'HS256' }
    )
  end

  def jwt_secret_key
    Rails.application.credentials.secret_key_base.presence ||
      ENV['SECRET_KEY_BASE'].presence ||
      Rails.application.secret_key_base
  end

  def find_user(token)
    payload = generate_jwt_token(token).first
    jti = payload['jti']
    return nil if jti.blank?

    session = UserSession.find_by(jti: jti)
    return nil unless session&.active?

    User.find_by(id: payload['user_id'])
  end

  def issue_jwt(user_id)
    jti = SecureRandom.uuid
    exp = 30.minutes.from_now

    token = JWT.encode({ user_id: user_id, jti: jti, exp: exp.to_i },
                       jwt_secret_key, 'HS256')

    create_user_session(user_id, jti, exp)

    token
  end

  def create_user_session(user_id, jti, exp)
    UserSession.create!(
      user_id: user_id,
      jti: jti,
      expires_at: exp,
      ip: request.remote_ip,
      user_agent: request.user_agent
    )
  end
end
