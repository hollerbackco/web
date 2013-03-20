module HollerbackApp
  class BaseApp < ::Sinatra::Base
    set :app_root, File.expand_path(".")
    helpers ::Sinatra::Warden::Helpers
    register ::Sinatra::ActiveRecordExtension

    configure :development do
      enable :logging, :dump_errors, :raise_errors

      ActiveRecord::Base.include_root_in_json = false
    end

    before do
      logger.info "[params] #{params.inspect}"
    end
  end
end
