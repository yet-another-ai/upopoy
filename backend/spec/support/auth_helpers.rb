module AuthHelpers
  def auth_headers_for(user = create(:user))
    Devise::JWT::TestHelpers.auth_headers({}, user)
  end
end
