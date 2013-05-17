# session routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/session' do
      logout
      authenticate(:password)
      if params.key? :device_token
        current_user.update_attributes(:device_token => params[:device_token])
      end
      {
        access_token: current_user.access_token,
        user: current_user
      }.to_json
    end

    post '/unauthenticated' do
      status 403
      {
        meta: {
          error_type: "AuthException",
          code: 403,
          msg: "Please specify correct email/password credentials or access_token"
        },
        data: nil
      }.to_json
    end
  end
end
