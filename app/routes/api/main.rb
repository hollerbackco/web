module HollerbackApp
  class ApiApp < BaseApp
    before '/me*' do
      authenticate(:api_token)
      app_version = request.env["HTTP_IOS_APP_VER"]
      if app_version and app_version != current_user.last_app_version
        current_user.update_attribute :last_app_version, app_version
        Hollerback::BMO.say("#{current_user.username} updated to #{app_version}")
      end

      ios_model_name = request.env["HTTP_IOS_MODEL_NAME"]
      if ios_model_name
        device = Device.find_by_access_token(params[:access_token])
        if device and device != device.description
          device.description = ios_model_name
          device.save
        end
      end
    end

    not_found do
      error_json 404, msg: "not found"
    end

    get '/' do
      success_json data: "Hollerback App Api v1"
    end

    get '/app/update' do
      user_version = request.env["HTTP_IOS_APP_VER"]
      current_version =  REDIS.get("app:current:version")
      name = logged_in? ? current_user.username : "update"

      #todo user_version is app store
      if ["1.0","1.0.1"].include? user_version
        {"message" => "app up to date"}.to_json
        return
      end

      if user_version != current_version
        data = {
          "message" => "Please Update Hollerback (#{current_version})",
          "button-text" => "Update",
          "url" => "http://www.hollerback.co/beta/#{name}"
        }
        success_json data: data
      else
        {"message" => "app up to date"}.to_json
      end
    end

    get '/me' do
      success_json data: current_user.as_json.merge(conversations: current_user.conversations)
    end

    post '/me/invites' do
      unless ensure_params(:invites)
        return error_json 400, msg: "missing required param: invites"
      end
      success_json data: nil
    end

    post '/me' do
      device = Device.find_by_access_token(params[:access_token])
      device.token = params["device_token"]

      if device.save
        success_json data: current_user.as_json.merge(conversations: current_user.conversations)
      else
        error_json 400, msg: current_user
      end
    end
  end
end
