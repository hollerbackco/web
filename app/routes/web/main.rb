module HollerbackApp
  class WebApp < BaseApp
    helpers do
      def omniauth
        @omniauth ||= request.env["omniauth.auth"]
      end
    end

    get '/' do
      haml :index, layout: false
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
      link_data = JSON.parse(REDIS.get("links:#{params[:token]}"))
      video = Video.find(link_data[0])
      phone = link_data[1]

      actor = {phone: phone}

      MetricsPublisher.delay.publish(actor, "invite:view")

      @name = video.user.username
      @video_url = video.url
      @thumb_url = video.thumb_url
      haml :video
    end

    get '/waitlist' do
      haml :waitlist
    end

    get '/android/:party' do
      party = params[:party]

      if Sinatra::Base.production? and ! params.key? :test
        Hollerback::SMS.send_message "+13033595357", "[android] #{party} visited the beta page"
      end

      app_link = AppLink.where(slug: party, segment: "android").first_or_create

      if params[:party] == "teamhollerback"
        app_link.increment!(:downloads_count)
        url = URI.escape("https://s3.amazonaws.com/hollerback-app-dev/distro/HollerbackAndroid-Stage.apk")
        redirect url
      elsif app_link.usable?
        app_link.increment!(:downloads_count)
        url = URI.escape("https://s3.amazonaws.com/hollerback-app-dev/distro/HollerbackAndroid.apk")
        redirect url
      else
        redirect "/"
      end
    end

    get '/beta/test/:branch' do
      url = URI.escape("https://s3.amazonaws.com/hb-distro/HollerbackApp-#{params[:branch]}.plist")
      redirect "itms-services://?action=download-manifest&url=#{url}"
    end

    get '/beta/:party' do
      party = params[:party]

      if Sinatra::Base.production? and ! params.key? :test
        Hollerback::SMS.send_message "+13033595357", "[ios] #{party} visited the beta page"
      end

      app_link = AppLink.where(slug: party, segment: "ios").first_or_create

      if params[:party] == "teamhollerback"
        app_link.increment!(:downloads_count)
        url = URI.escape("https://s3.amazonaws.com/hb-distro/HollerbackApp-staging.plist")
        redirect "itms-services://?action=download-manifest&url=#{url}"
      elsif app_link.usable?
        app_link.increment!(:downloads_count)
        url = URI.escape("https://s3.amazonaws.com/hb-distro/HollerbackApp-master.plist")
        redirect "itms-services://?action=download-manifest&url=#{url}"
      else
        redirect "/"
      end
    end

    ['/fly', '/fly/:from_name'].each do |path|
      get path do
        #@signup_test = ab_test("signup_waitlist", 'twitter', 'email')
        if params.key? "from_name"
          session[:from] = params[:from_name]
        end

        haml :glass, layout: :pledge
      end
    end

    get '/auth/:provider/callback' do
      pledger = Pledger.where(username: omniauth[:info][:nickname]).first_or_create do |p|
        p.name = omniauth[:info][:name]
        p.username = omniauth[:info][:nickname]
        p.auth_token = omniauth[:credentials][:token]
        p.auth_secret = omniauth[:credentials][:secret]
        p.meta =  omniauth[:extra][:raw_info].as_json

        if session.key? :from
          if from = Pledger.where(username: session[:from]).first
            p.parent_id = from.id
          end
        end
      end
      redirect to("/pledge/#{pledger.username}")
    end

    get "/thanks" do
      finished("signup_waitlist")
      haml :entries, layout: :pledge
    end

    get "/pledge/:username" do
      finished("signup_waitlist")
      @pledger = Pledger.where(username: params[:username]).first

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
