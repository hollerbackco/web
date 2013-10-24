module HollerbackApp
  class BaseApp < Sinatra::Base
    configure :development, :staging, :test do
      ::GCMS = GCM.new ENV["GCM_KEY"]
      pemfile = File.join(app_root, 'config', 'apns', 'apns_enterprise_dev.pem')
      Hollerback::Push.configure(pemfile, false)
    end

    configure :production do
      require 'newrelic_rpm'
      ::GCMS = GCM.new ENV["GCM_KEY"]
      pemfile = File.join(app_root, 'config', 'apns', 'apns_enterprise_prod.pem')
      Hollerback::Push.configure(pemfile, true)
    end
  end
end
