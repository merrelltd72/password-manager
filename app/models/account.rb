# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :user
  belongs_to :category

  encrypts :password
end
