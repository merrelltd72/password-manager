# frozen_string_literal: true

# Controller handling user-related actions such as user creation.
class UsersController < ApplicationController
  # Create new user
  def create
    user = User.new(user_params)
    if user.save
      render json: { message: 'User created successfully' }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :bad_request
    end
  end

  private

  def user_params
    params.permit(:username, :email, :password, :password_confirmation)
  end
end
