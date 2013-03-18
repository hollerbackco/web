module HollerbackApp
  class WebApp < BaseApp
    get '/' do
      haml :index
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
  end
end
