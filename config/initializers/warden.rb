Warden::Manager.serialize_into_session{|user| user.id }
Warden::Manager.serialize_from_session{|id| User[id] }

Warden::Manager.before_failure do |env,opts|
  env['REQUEST_METHOD'] = 'POST'
end

Warden::Strategies.add(:password) do
  def valid?
    params['email'] && params['password']
  end

  def authenticate!
    user = User.authenticate(
      params['email'],
      params['password']
      )
    user.nil? ? fail!('Could not log in') : success!(user, 'Successfully logged in')
  end
end

Warden::Strategies.add(:api_token) do
  def authenticate!
    if token = params["access_token"]
      user = User.authenticate_with_access_token(token.strip)
      user.nil? ? fail!('No api key') : success!(user)
    end
  end
end

