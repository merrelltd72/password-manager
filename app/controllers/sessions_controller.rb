class SessionsController < ApplicationController

  #user login method
  def create
    if request.env['omniauth.auth']
      auth = request.env['omniauth.auth']
      # user = User.find_or_create_from_auth_hash(auth)
      user = User.find_or_create_by(
        username: auth.info.name, 
        email: auth.info.email,
        provider: auth.provider,
      )
      user.assign_attributes(
        token: auth.credentials.token,
        uid: auth.uid
      )
      user.save(validate: false)
      pp user
      jwt = JWT.encode(
        {
        user_id: user.id,
        exp: 1.hour.from_now.to_i
        },
        Rails.application.credentials.fetch(:secret_key_base),
        "HS256"
      )
      # render json: { jwt: jwt, email: user.email, user_id: user.id }
      redirect_to "http://localhost:5173/?jwt=#{jwt}", notice: 'Signed in with Google successfully!'
    else
      user = User.find_by(email: params[:email])
      if user && user.authenticate(params[:password])
        jwt = JWT.encode(
          {
            user_id: user.id, #the data to encode
            exp: 24.hours.from_now.to_i # the expiration time
          },
          Rails.application.credentials.fetch(:secret_key_base), #the secret key
          "HS256" # the encryption algorithm
          )
        render json: { jwt: jwt, email: user.email, user_id: user.id }, status: :created
      else
        render json: {}, status: :unauthorized
      end
    end
  end

end
