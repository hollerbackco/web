module HollerbackApp
  class BaseApp < ::Sinatra::Base
    set :app_root, File.expand_path(".")
    helpers ::Sinatra::Warden::Helpers
    helpers ::Sinatra::CoreHelpers
    register ::Sinatra::ActiveRecordExtension

    helpers do
      def t(*args)
        I18n.t(*args)
      end
    end

    configure do
      ActiveRecord::Base.include_root_in_json = false
      I18n.load_path = Dir[File.join(settings.app_root, 'config', 'locales', '*.yml')]
      #I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
      #I18n.backend.load_translations
    end

    configure :development do
      enable :logging, :dump_errors, :raise_errors
    end

    configure :development do
      ::APNS.pem = File.join(app_root, 'config', 'apns', 'apns_dev.pem')
    end

    configure :production do
      ::APNS.pem = File.join(app_root, 'config', 'apns', 'apns_prod.pem')
      ::APNS.host = 'gateway.push.apple.com'
    end

    before do
      logger.info "[params] #{params.inspect}"
    end
  end
end
