module HollerbackApp
  class BaseApp < ::Sinatra::Base
    set :app_root, File.expand_path(".")

    helpers ::Sinatra::Warden::Helpers
    helpers ::Sinatra::CoreHelpers
    register Sinatra::MultiRoute
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

    configure :development, :staging, :test do
      ::GCMS = GCM.new ENV["GCM_KEY"]
      ::APNS.pem = File.join(app_root, 'config', 'apns', 'apns_dev.pem')
    end

    configure :production do
      require 'newrelic_rpm'
      ::GCMS = GCM.new ENV["GCM_KEY"]
      ::APNS.pem = File.join(app_root, 'config', 'apns', 'apns_enterprise_prod.pem')
      ::APNS.host = 'gateway.push.apple.com'
    end
  end
end
