module HollerbackApp
  class ApiApp < BaseApp
    before '/me*' do
      authenticate(:api_token)
      logger.info("[user: #{current_user.id}]")
      app_version = request.env["HTTP_IOS_APP_VER"]
      if app_version and app_version != current_user.last_app_version
        current_user.update_attribute :last_app_version, app_version
        Hollerback::BMO.say("#{current_user.username} updated to #{app_version}")
      end

      current_user.last_active_at = Time.now
      current_user.save

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

    # only for dev
    post '/log' do
      p params[:p]
    end

    get '/' do
      logger.info "hello"
      success_json data: "Hollerback App Api v1"
    end

    get '/app/update' do
      user_version = request.env["HTTP_IOS_APP_VER"]
      #current_version =  REDIS.get("app:current:version")
      name = logged_in? ? current_user.username : "update"

      #todo user_version is app store
      if user_version.match(/1./)
        #{"message" => "app up to date"}.to_json
        return
      else
        data = {
          "message" => "We've moved to the App Store! Please delete this version",
          "button-text" => "Go to App Store",
          "url" => "http://www.hollerback.co/beta/#{name}"
        }
        success_json data: data
      end
    end

    get '/me' do
      success_json data: current_user.as_json.merge(conversations: current_user.conversations)
    end

    get '/me/friends' do
      users_json = current_user.friends.map do |friend|
        friend.as_json.merge({
          :name => friend.also_known_as({:for => user}),
          :is_blocked => current_user.muted?(friend)
        })
      end

      success_json({:data => users_json})
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
      current_user.username = params["username"] if params.key? "username"
      current_user.phone = params["phone"] if params.key? "phone"

      if device.save and current_user.save
        success_json data: current_user
      else
        error_json 400, msg: current_user
      end
    end
  end
end
