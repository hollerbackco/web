module HollerbackApp
  class WebApp < BaseApp
    get '/' do
      haml :index, layout: false
    end

    get '/waitlist' do
      haml :waitlist
    end

    get '/terms' do
      haml :terms
    end

    get '/privacy' do
      haml :privacy
    end

    #TODO deprecate, replaced by v/:token
    get '/from/:username/:id' do
      video = Video.find_by_code(params[:id])
      not_found if video.user.username != params[:username]

      @name = video.user.username
      @video_url = video.url
      @thumb_url = video.thumb_url
      haml :video
    end

    get '/v/:token' do
      #link_data = JSON.parse(REDIS.get("links:#{params[:token]}"))
      #video = Video.find(link_data[0])
      #phone = link_data[1]

      #actor = {phone: phone}

      #MetricsPublisher.delay.publish(actor, "invite:view")

      #@name = video.user.username
      #@video_url = video.url
      #@thumb_url = video.thumb_url
      #haml :video
      redirect "/invite"
    end

    get "/thanks" do
      finished("signup_waitlist")
      haml :entries, layout: :pledge
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

    post '/waitlist.json' do
      waitlister = Waitlister.new(email: params[:email])
      if waitlister.save
        {
          :success => true
        }.to_json
      else
        @errors = waitlister.errors
        {
          :success => false,
          :msg => waitlister.errors.first
        }.to_json
      end
    end

    get '/client' do
      haml :client, layout: false
    end
  end
end
