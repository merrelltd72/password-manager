# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExportRun, type: :model do
  let(:user) { User.create!(username: 'testuser', email: 'testuser@example.com', password: 'password1') }

  it 'is invalid without a format' do
    run = ExportRun.new(user: user)
    expect(run).not_to be_valid
    expect(run.errors[:format]).to include("can't be blank")
  end

  it 'is invalid with an unsupported format' do
    run = ExportRun.new(user: user, format: 'xml')
    expect(run).not_to be_valid
    expect(run.errors[:format]).to include('is not included in the list')
  end
end
