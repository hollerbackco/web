module HollerbackApp
  class WebApp < BaseApp
    def http_authorized?
      @auth ||=  Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [ENV["ADMIN_USERNAME"],ENV["ADMIN_PASSWORD"]]
    end

    def http_protected
      unless http_authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw(:halt, [401, "Oops... we need your login name & password\n"])
      end
    end

    before '/madmin*' do
      http_protected
    end

    get '/madmin' do
      @users = User.all
      @videos = Video.limit(25)
      haml "admin/index".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/metrics' do
      @app_links = AppLink.all
      haml "admin/stats".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/app_links' do
      @app_links = AppLink.all
      haml "admin/app_links".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/waitlist' do
      @waitlisters = Waitlister.all
      haml "admin/invite_requests".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/stats' do
    stats = Hollerback::Statistics.new
      {
        users_count: stats.users_count,
        conversations_count: stats.conversations.count,
        videos_count: stats.videos_sent_count,
        received_count: stats.videos_received_count,
        members_per_conversation_avg: stats.members_in_conversation_avg,
        videos_per_conversation_avg: stats.videos_in_conversation_avg
      }.to_json
    end
  end
end
