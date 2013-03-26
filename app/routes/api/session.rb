# session routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/session' do
      authenticate(:password)
      {
        params: params,
        access_token: current_user.access_token,
        user: current_user,
        session: session
      }.to_json
    end

    post '/unauthenticated' do
      {
        meta: {
          error_type: "AuthException",
          code: 403,
          error_message: "Please specify correct email/password credentials or access_token"
        },
        data: nil
      }.to_json
    end
  end
end
