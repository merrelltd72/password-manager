# frozen_string_literal: true

class SessionsController < ApplicationController
  # user login method
  def create
    user = if request.env['omniauth.auth']
             authenticate_oath(request.env['omniauth.auth'])
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
  rescue StandardError => e
    render json: { error: 'Authentication failed' }, status: :internal_server_error
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

  def authenticate_oath(auth)
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
               Rails.application.credentials.fetch(:secret_key_base), 'HS256')
  end

  def decode_jwt
    token = cookies.signed[:jwt]
    JWT.decode(
      token,
      Rails.application.credentials.fetch(:secret_key_base),
      true,
      { algorithm: 'HS256' }
    )
  end
end
