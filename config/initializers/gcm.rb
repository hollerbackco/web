module HollerbackApp
  class BaseApp < Sinatra::Base
    configure do
      #::GCMS = GCM.new ENV["GCM_KEY"]
      Hollerback::GcmWrapper::init #initialize gcm
    end
  end
end
