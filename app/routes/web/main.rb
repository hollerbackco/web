module HollerbackApp
  class WebApp < BaseApp
    get '/' do
      haml :index
    end

    get '/wait' do
      haml :index
    end
  end
end
