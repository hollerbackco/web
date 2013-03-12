require 'json'

module HollerbackApp
  class Main < BaseApp
    before do
      logger.info "[params] #{params.inspect}"
    end

    get '/' do
      {
        page: {
          title: "home",
          body: "welcome to the new api"
        }
      }.to_json
    end
  end
end
