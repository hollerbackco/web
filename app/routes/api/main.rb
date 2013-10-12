module HollerbackApp
  class ApiApp < BaseApp
    before '/me*' do
      authenticate(:api_token)
      app_version = request.env["HTTP_IOS_APP_VER"]
      if app_version and app_version != current_user.last_app_version
        current_user.update_attribute :last_app_version, app_version
      end
    end

    not_found do
      error_json 404, "not found"
    end

    get '/' do
      success_json data: "Hollerback App Api v1"
    end

    get '/app/update' do
      user_version = request.env["HTTP_IOS_APP_VER"]
      current_version =  REDIS.get("app:current:version")
      name = logged_in? ? current_user.username : "update"

      if user_version != current_version
        data = {
          "message" => "Please Update Hollerback (#{app_version})",
          "button-text" => "Update",
          "url" => "http://www.hollerback.com/beta/#{name}"
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
      obj = {}
      obj[:email] = params["email"] if params.key? "email"
      obj[:name]  = params["name"] if params.key? "name"
      obj[:device_token]  = params["device_token"] if params.key? "device_token"
      obj[:phone]  = params["phone"] if params.key? "phone"

      if current_user.update_attributes obj
        success_json data: current_user.as_json.merge(conversations: current_user.conversations)
      else
        error_json 400, msg: current_user
      end
    end
  end
end
