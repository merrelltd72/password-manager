# frozen_string_literal: true

module ErrorResponseHelper
  def expect_json_error_response(status, message_presence: true)
    expect(response).to have_http_status(status)
    body = JSON.parse(response.body)

    expect(body.keys & %w[error errors]).not_to be_empty

    return unless message_presence

    if body.key?('error')
      expect(body['error']).to be_a(String)
      expect(body['error']).not_to be_empty
    elsif body.key?('errors')
      expect(body['errors']).to be_an(Array)
      expect(body['errors']).not_to be_empty
    end
  end
end
