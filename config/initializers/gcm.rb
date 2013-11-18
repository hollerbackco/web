module HollerbackApp
  class BaseApp < Sinatra::Base
    configure do
      ::GCMS = GCM.new ENV["GCM_KEY"]
    end
  end
end
