require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  test "create" do
    assert_difference "User.count", 1 do
      post '/users.json', params: {
        username: "Test", email: "test@example.com", password: "password", password_Confirmation: "password"
      }
      assert_response 201
    end
  end

end
