# frozen_string_literal: true

class SessionsController < ApplicationController
  # user login method
  def create
    if request.env['omniauth.auth']
      auth = request.env['omniauth.auth']
      # user = User.find_or_create_from_auth_hash(auth)
      user = User.find_or_create_by(
        username: auth.info.name,
        email: auth.info.email,
        provider: auth.provider
      )
      user.assign_attributes(
        token: auth.credentials.token,
        uid: auth.uid
      )
      user.save(validate: false)
      jwt = JWT.encode(
        {
          user_id: user.id,
          exp: 1.hour.from_now.to_i
        },
        Rails.application.credentials.fetch(:secret_key_base),
        'HS256'
      )
      cookies.signed[:jwt] = { value: jwt, httponly: true }
      # render json: { jwt: jwt, email: user.email, user_id: user.id }
      redirect_to 'http://localhost:5173/accounts', notice: 'Signed in with Google successfully!'
    else
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password])
        jwt = JWT.encode(
          {
            user_id: user.id, # the data to encode
            exp: 24.hours.from_now.to_i # the expiration time
          },
          Rails.application.credentials.fetch(:secret_key_base), # the secret key
          'HS256' # the encryption algorithm
        )
        cookies.signed[:jwt] = { value: jwt, httponly: true }
        render json: { email: user.email, user_id: user.id }, status: :created
      else
        render json: {}, status: :unauthorized
      end
    end
  end

  def destroy
    cookies.delete(:jwt)
    render json: { message: 'Logged out successfully' }
  end

  def isloggedin
    if current_user
      decoded_token = generate_token
      User.find_by(id: decoded_token[0]['user_id'])
      user = User.find_by(id: decoded_token[0]['user_id'])
      render json: { logged_in: true, user: user }, status: 200
    else
      render json: { logged_in: false }, status: :unauthorized
    end
  end

  private

  def generate_token
    token = cookies.signed[:jwt]
    JWT.decode(
      token,
      Rails.application.credentials.fetch(:secret_key_base),
      true,
      { algorithm: 'HS256' }
    )
  end
end
