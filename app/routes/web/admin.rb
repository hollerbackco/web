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

    post '/madmin/app/version' do
      if params[:version]
        REDIS.set("app:current:version", params[:version])
        "success"
      else
        "please specify version number"
      end
    end

    get '/madmin' do
      @broken = Video.where(:filename => nil)
      @videos = Video.paginate(:page => params[:page], :per_page => 20)
      haml "admin/index".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/videos' do
      @videos = Video.paginate(:page => params[:page], :per_page => 20)
      haml "admin/index".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/conversations/:id' do
      @conversation = Conversation.find(params[:id])
      @members = @conversation.members
      @videos = @conversation.videos

      haml "admin/memberships".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/users' do
      @users = User.order("created_at ASC")
        .includes(:memberships, :messages, :devices)
        .paginate(:page => params[:page], :per_page => 50)

      haml "admin/users".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/users/:id' do
      @user = User.includes(:memberships, :messages).find(params[:id])
      @memberships = @user.memberships
      @messages = @user.messages

      @users = User.order("created_at ASC").includes(:memberships, :messages, :devices).all
      haml "admin/users/show".to_sym, layout: "layouts/admin".to_sym
    end

    get '/madmin/users/:id/edit' do
      @user = User.find(:id)
      haml "admin/users/edit".to_sym, layout: "layouts/admin".to_sym
    end

    put '/madmin/users/:id' do
      @user = User.find(:id)
      if @user.update_attributes(params[:user])
        redirect "/madmin/users/#{@user.id}/edit"
      else
        haml "admin/users/edit".to_sym, layout: "layouts/admin".to_sym
      end
    end

    get '/madmin/invites' do
      @invites = Invite.order("created_at DESC").includes(:inviter).paginate(:page => params[:page], :per_page => 50)
      haml "admin/invites".to_sym, layout: "layouts/admin".to_sym
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
        conversations_count: stats.conversations_count,
        videos_count: stats.videos_sent_count,
        received_count: stats.videos_received_count,
        members_per_conversation_avg: stats.members_in_conversations_avg,
        videos_per_conversation_avg: stats.videos_in_conversations_avg
      }.to_json
    end
  end
end
