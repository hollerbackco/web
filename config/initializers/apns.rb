module HollerbackApp
  class BaseApp < Sinatra::Base
    configure :development, :staging, :test do
      ::GCMS = GCM.new ENV["GCM_KEY"]
      ::APNS.pem = File.join(app_root, 'config', 'apns', 'apns_enterprise_dev.pem')
    end

    configure :production do
      require 'newrelic_rpm'
      ::GCMS = GCM.new ENV["GCM_KEY"]
      ::APNS.pem = File.join(app_root, 'config', 'apns', 'apns_enterprise_prod.pem')
      ::APNS.host = 'gateway.push.apple.com'
    end
  end
end
