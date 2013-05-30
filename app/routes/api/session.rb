# session routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/session' do
      logout
      authenticate(:password)

      p params

      if params.key?("platform") and params.key?("device_token")
        current_user.devices.where({
          :platform => params["platform"],
          :token => params["device_token"]
        }).first_or_create
      elsif params.key? :device_token
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

    delete '/session/:platform' do
      authenticate(:api_token)
      logout
      current_user.devices.where(:platform => params[:platform]).destroy_all if current_user
    end
  end
end
