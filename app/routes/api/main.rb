module HollerbackApp
  class ApiApp < BaseApp
    before '/me*' do
      p request['iOS-App-Ver']
      authenticate(:api_token)
    end

    before '/contacts*' do
      authenticate(:api_token)
    end

    not_found do
      error_json 404, "not found"
    end

    get '/' do
      success_json data: "Hollerback App Api v1"
    end

    get '/me' do
      success_json data: current_user.as_json.merge(conversations: current_user.conversations)
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

    post '/me/verify' do
      if current_user.verify! params["code"]
        success_json data: current_user.as_json.merge(conversations: current_user.conversations)
      else
        error_json 400, msg: "incorrect code"
      end
    end
  end
end
