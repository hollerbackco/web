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

    get '/video' do
      haml :video
    end

    get '/waitlist' do
      haml :waitlist
    end

    get '/beta' do
      haml :test, layout: false
    end

    get '/beta/download' do
      url = URI.escape("https://s3.amazonaws.com/hollerback-app-dev/distro/HollerbackAppEnterprise.plist")
      redirect "itms-services://?action=download-manifest&url=#{url}"
    end

    ['/fly', '/fly/:from_name'].each do |path|
      get path do
        @signup_test = ab_test("signup_waitlist", 'twitter', 'email')
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
