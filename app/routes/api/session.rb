# session routes
module HollerbackApp
  class ApiApp < BaseApp
    post '/session' do
      unless ensure_params(:phone)
        return error_json 400, msg: "missing required params"
      end

      logout

      user = User.find_by_phone_normalized(params["phone"])

      if user
        Hollerback::SMS.send_message user.phone_normalized, "Verification Code: #{user.verification_code}"
        {
          user: user.as_json
        }.to_json
      else
        not_found
      end
    end

    post '/verify' do
      unless ensure_params(:phone, :code)
        return error_json 400, msg: "missing required params"
      end
      authenticate(:password)

      #authenticate(:password)
      # remove all devices with device_token that is not blank
      if params.key "device_token" and !params["device_token"].blank?
        devices = Device.where("token" => params["device_token"])
        if devices.any?
          p "destroying devices ---"
          p devices
        end
        devices.destroy_all
      end

      device = user.device_for(params["device_token"], params["platform"])

      {
        access_token: device.access_token,
        user: user.as_json.merge(access_token: device.access_token)
      }.to_json
    end


    post '/unauthenticated' do
      $stdout.puts("source=#{settings.environment} measure.unauthenticated=1")
      status 403
      {
        meta: {
          error_type: "AuthException",
          code: 403,
          msg: "Incorrect code or access_token"
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
