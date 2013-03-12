require File.expand_path('./config/environment')

module HollerbackApp
  class Session < BaseApp
    before do
      logger.info "[params] #{params.inspect}"
    end

    post '/' do
    end
  end
end
