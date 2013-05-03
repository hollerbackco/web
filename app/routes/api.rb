module HollerbackApp
  class ApiApp < BaseApp
    before do
      content_type 'application/json'
    end

    configure do
      use Warden::Manager do |config|
        config.failure_app = HollerbackApp::ApiApp

        config.scope_defaults :default,
          strategies: [:password, :api_token],
          action: '/unauthenticated'
      end
    end
  end
end
