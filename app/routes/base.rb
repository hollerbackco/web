module HollerbackApp
  class BaseApp < ::Sinatra::Base
    set :app_root, File.expand_path(".")
    helpers ::Sinatra::Warden::Helpers
    helpers ::Sinatra::CoreHelpers
    register ::Sinatra::ActiveRecordExtension

    configure :development do
      enable :logging, :dump_errors, :raise_errors

      ActiveRecord::Base.include_root_in_json = false
    end

    configure do
      ::APNS.pem = File.join(app_root, 'config', 'apns', 'dev.pem')
      # this is the file you just created
      ::APNS.port = 2195
    end

    before do
      logger.info "[params] #{params.inspect}"
    end
  end
end
