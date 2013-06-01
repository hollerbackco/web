# session routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/session' do
      logout
      authenticate(:password)

      device = current_user.device_for(params["device_token"], params["platform"])

      {
        access_token: device.access_token,
        user: current_user.as_json.merge(access_token: device.access_token)
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

    delete '/session/?:platform?' do
      authenticate(:api_token)
      current_user.devices.where(:access_token => params["access_token"]).destroy_all if current_user
      logout
    end
  end
end
