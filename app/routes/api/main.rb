module HollerbackApp
  class ApiApp < BaseApp
    before '/me*' do
      authenticate(:api_token)
    end

    before '/contacts*' do
      authenticate(:api_token)
    end

    not_found do
      {
        meta: {
          code: 404,
          msg: "not found",
          errors: []
        },
        data: nil
      }.to_json
    end

    get '/' do
      {
        msg: "Hollerback App Api v1"
      }.to_json
    end

    get '/contacts/check' do
      numbers = params["numbers"]
      contact_checker =  Hollerback::ContactChecker.new(numbers, current_user)

      contacts = contact_checker.contacts

      #todo remove this after launch
      user = User.where(email: "williamldennis@gmail.com").first
      contacts = contacts - [user]

      if params["first"]
        user.name = "Will Dennis - Cofounder of Hollerback"
        contacts << user if user
      end

      {
        meta: {
          code: 200
        },
        data: contacts
      }.to_json
    end

    get '/me' do
      {
        meta: {
          code: 200
        },
        data: current_user.as_json.merge(conversations: current_user.conversations)
      }.to_json
    end

    post '/me' do
      obj = {}
      obj[:email] = params["email"] if params.key? "email"
      obj[:name]  = params["name"] if params.key? "name"
      obj[:device_token]  = params["device_token"] if params.key? "device_token"
      obj[:phone]  = params["phone"] if params.key? "phone"

      if current_user.update_attributes obj
        {
          meta: {
            code: 200
          },
          data: current_user.as_json.merge(conversations: current_user.conversations)
        }.to_json
      else
        error_json 400, msg: current_user
      end
    end

    post '/me/verify' do
      if current_user.verify! params["code"]
        {
          meta: {
            code: 200
          },
          data: current_user.as_json.merge(conversations: current_user.conversations)
        }.to_json
      else
        error_json 400, msg: "incorrect code"
      end
    end

    ########################################
    # conversations
    ########################################

    get '/me/conversations' do
      conversations = current_user.conversations.map do |conversation|
        conversation_json conversation
      end

      ConversationRead.perform_async(current_user.id)
      cache_key = "#{current_user.memcache_key}/conversations"

      {
        meta: {
          code: 200
        },
        data: {
          conversations: conversations
        }
      }.to_json
    end

    # params
    #   invites: array of phone numbers
    post '/me/conversations' do
      unless ensure_params :invites
        return error_json 400, msg: "missing invites param"
      end

      unless conversation = Conversation.find_by_phone_numbers(current_user, params[:invites])
        success = Conversation.transaction do
          conversation = current_user.conversations.create(creator: current_user)
          inviter = Hollerback::ConversationInviter.new(current_user, conversation, params[:invites])
          inviter.invite
        end

        if success
          Keen.publish("conversations:create", {
            :user => {
              id: current_user.id,
              username: current_user.username
            },
            :total_invited_count => params[:invites].count,
            :already_users_count => conversation.members.count
          })
        end
      end

      if conversation.errors.blank?
        {
          meta: {
            code: 200
          },
          data: conversation_json(conversation)
        }.to_json
      else
        error_json 400, for: conversation, msg: "problem updating"
      end
    end

    get '/me/conversations/:id' do
      begin
        conversation = current_user.conversations.find(params[:id])
        {
          meta: {
            code: 200
          },
          data: conversation_json(conversation)
        }.to_json
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    post '/me/conversations/:id/leave' do
      membership = current_user.memberships.where({
        conversation_id: params[:id]

      }).first
      if membership.destroy
        {
          meta: {
            code: 200
          },
          data: nil
        }.to_json
      else
        error_json 400, msg: "conversation could not be deleted"
      end
    end

    get '/me/conversations/:conversation_id/invites' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        {
          meta: {
            code: 200
          },
          data: conversation.invites
        }.to_json
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    get '/me/conversations/:conversation_id/members' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        {
          meta: {
            code: 200
          },
          data: conversation.members
        }.to_json
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    get '/me/conversations/:conversation_id/videos' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])

        ConversationRead.perform_async(current_user.id)

        cache_key = "#{current_user.memcache_key}/conversation/#{conversation.id}-#{conversation.updated_at}/videos#{params[:page]}"

        res = HollerbackApp::BaseApp.settings.cache.fetch(cache_key, 1.hour) do
          scoped_videos = conversation.videos_for(current_user).scoped

          if params[:page]
            scoped_videos = scoped_videos.paginate(:page => params[:page], :per_page => 20)
          end

          videos = scoped_videos.with_read_marks_for(current_user)
          video_json = videos.map do |video|
            video.as_json_for_user current_user
          end

          if params[:page]
            last_page = videos.current_page == videos.total_pages
          end

          {
            meta: {
              code: 200,
              last_page: last_page
            },
            data: video_json
          }.to_json
        end
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    ########################################
    # videos
    ########################################

    get '/me/conversations/:conversation_id/videos/:id/user' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        video = conversation.videos.find params[:id]
        {
          meta: {
            code: 200
          },
          data: video.user
        }.to_json
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    post '/me/videos/:id/read' do
      video = Video.find(params[:id])
      video.mark_as_read! for: current_user
      conversation = video.conversation

      #todo make sure this doesnt get reset before video is marked as read.
      current_user.memcache_key_touch
      HollerbackApp::BaseApp.settings.cache.delete "user/#{current_user.id}/conversations/#{conversation.id}-#{conversation.updated_at}"
      VideoRead.perform_async(video.id, current_user.id)

      {
        meta: {
          code: 200
        },
        data: video.as_json_for_user(current_user)
      }.to_json
    end

    post '/me/conversations/:id/videos/parts' do
      if !ensure_params :parts
        return error_json 400, msg: "missing parts param"
      end

      conversation = current_user.conversations.find(params[:id])
      video = conversation.videos.create(user: current_user)

      VideoStitchAndSend.perform_async(params[:parts], video.id)

      {
        meta: {
          code: 200
        },
        data: video
      }.to_json
    end

    post '/me/conversations/:id/videos' do
      if !ensure_params :filename
        return error_json 400, msg: "missing filename param"
      end

      begin
        conversation = current_user.conversations.find(params[:id])
        video = conversation.videos.build(
          user: current_user,
          filename: params[:filename]
        )

        if video.save
          video.ready!
          conversation.touch
          current_user.memcache_key_touch
          Hollerback::NotifyRecipients.new(video).run

          #todo: move this to async job
          Keen.publish("video:create", {
            id: video.id,
            receivers_count: (conversation.members.count - 1),
            conversation: {
              id: conversation.id,
              videos_count: conversation.videos.count
            },
            user: {id: current_user.id, username: current_user.username}
          })

          {
            meta: {
              code: 200
            },
            data: video
          }.to_json
        else
          error_json 400, for: video
        end

      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end
  end
end
