module HollerbackApp
  class WebApp < BaseApp
    helpers do
      def sms_download_notification(name)
        if Sinatra::Base.production? and ! params.key? :test
          Hollerback::SMS.send_message "+13033595357", "[ios] #{name} was sent to the appstore"
        end
      end

      def ios?
        p request.user_agent
        user_agent = Hollerback::UserAgent.new(request.user_agent)
        user_agent.ios?
      end

      def keen

      end
    end

    ['/download', '/invite', '/v/:token', '/usc'].each do |location|
      get location do
        if ios?
          if location == "usc"
            MetricsPublisher.delay.publish_delay("email:usc:app_visit")
          end
          url = 'http://appstore.com/hollerback'
          redirect url
        else
          redirect '/android/wait'
        end
      end
    end

    get '/beta/test/:branch' do
      url = URI.escape("https://s3.amazonaws.com/hb-distro/HollerbackApp-#{params[:branch]}.plist")
      redirect "itms-services://?action=download-manifest&url=#{url}"
    end

    get '/beta/:party' do
      app_link = AppLink.where(slug: params[:party], segment: "ios").first_or_create
      if params[:party] == "teamhollerback"
        url = URI.escape("https://s3.amazonaws.com/hb-distro/HollerbackApp-staging.plist")
        url = "itms-services://?action=download-manifest&url=#{url}"
      elsif app_link.usable?
        #sms_download_notification(params[:party])
        app_link.increment!(:downloads_count)

        #to enterprise build
        #url = URI.escape("https://s3.amazonaws.com/hb-distro/HollerbackApp-master.plist")
        #url =  "itms-services://?action=download-manifest&url=#{url}"

        url = "http://appstore.com/hollerback"
      else
        url = "/"
      end
      redirect url
    end

    #get '/android/:party' do
      #party = params[:party]

      #if Sinatra::Base.production? and ! params.key? :test
        #Hollerback::SMS.send_message "+13033595357", "[android] #{party} visited the beta page"
      #end

      #app_link = AppLink.where(slug: party, segment: "android").first_or_create

      #if params[:party] == "teamhollerback"
        #app_link.increment!(:downloads_count)
        #url = URI.escape("https://s3.amazonaws.com/hollerback-app-dev/distro/HollerbackAndroid-Stage.apk")
        #redirect url
      #elsif app_link.usable?
        #app_link.increment!(:downloads_count)
        #url = URI.escape("https://s3.amazonaws.com/hollerback-app-dev/distro/HollerbackAndroid.apk")
        #redirect url
      #else
        #redirect "/"
      #end
    #end
  end
end
