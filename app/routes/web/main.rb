module HollerbackApp
  class WebApp < BaseApp
    get '/' do
      haml :index, layout: false
    end

    get '/video' do
      haml :video
    end

    get '/waitlist' do
      haml :waitlist
    end

    post '/waitlist' do
      waitlister = Waitlister.new(email: params[:email])
      if waitlister.save
        haml :thanks
      else
        @errors = waitlister.errors
        haml :waitlist
      end
    end

    get '/client' do
      haml :client, layout: false
    end
  end
end
