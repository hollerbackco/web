module HollerbackApp
  class ApiApp < BaseApp
    get '/me/sync' do
      if params["updated_at"]
        updated_at = Time.parse params["updated_at"]
        scope = scope.where("conversations.updated_at > ?", updated_at)
      end
    end
  end
end
