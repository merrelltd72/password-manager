module AuthenticationHelper
  def self.current_user
    Thread.current[:current_user]
  end
end
