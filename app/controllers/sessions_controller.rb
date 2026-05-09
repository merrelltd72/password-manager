# frozen_string_literal: true

# This class handles user sessions, including login, logout, and checking if a user is logged in.
# It supports both email/password authentication and OAuth authentication.
# JWT tokens are used for session management, stored in HTTP-only cookies for security.
class SessionsController < ApplicationController
  # user login method
  def create
    user = if request.env['omniauth.auth'].present?
             authenticate_oauth(request.env['omniauth.auth'])
           else
             authenticate_email(params[:email], params[:password])
           end

    if user
      jwt = issue_jwt(user.id)
      cookies.signed[:jwt] = { value: jwt, httponly: true }
      render json: { email: user.email, user_id: user.id }, status: :created
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  rescue StandardError
    render json: { error: 'Authentication failed' }, status: :internal_server_error
  end

  def oauth_callback
    user = authenticate_oauth(request.env['omniauth.auth'])
    jwt = issue_jwt(user.id)
    cookies.signed[:jwt] = { value: jwt, httponly: true }
    render json: { email: user.email, user_id: user.id }, status: :created
  rescue StandardError
    render json: { error: 'Authentication failed' }, status: :internal_server_error
  end

  def oauth_failure
    error = params[:message].presence || 'Authentication failed'
    render json: { error: error }, status: :unauthorized
  end

  def destroy
    cookies.delete(:jwt)
    render json: { message: 'Logged out successfully' }, status: :ok
  end

  def isloggedin
    return render json: { logged_in: false }, status: :unauthorized unless current_user

    render json: { logged_in: true, user: current_user }, status: :ok
  rescue JWT::DecodeError, JWT::ExpiredSignature
    render json: { logged_in: false }, status: :unauthorized
  end

  private

  def authenticate_oauth(auth)
    User.find_or_create_by(
      username: auth.info.name,
      email: auth.info.email,
      provider: auth.provider
    ).tap do |user|
      user.update(token: auth.credentials.token, uid: auth.uid)
    end
  end

  def authenticate_email(email, password)
    user = User.find_by(email: email)
    user&.authenticate(password) ? user : nil
  end

  def issue_jwt(user_id)
    JWT.encode({ user_id: user_id, exp: 24.hours.from_now.to_i },
               jwt_secret_key, 'HS256')
  end

  def decode_jwt
    token = cookies.signed[:jwt]
    JWT.decode(
      token,
      jwt_secret_key,
      true,
      { algorithm: 'HS256' }
    )
  end
end
