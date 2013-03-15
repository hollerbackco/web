require File.expand_path('./config/environment')

module HollerbackApp
  class Session < BaseApp
    post '/' do
      authenticate
      {access_token: current_user.access_token, user: current_user}.to_json
    end
  end
end
