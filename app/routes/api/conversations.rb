module HollerbackApp
  class ApiApp < BaseApp
    get '/me/conversations' do
      updated_at = nil

      scope = current_user.conversations

      if params["page"]
        scope = scope.paginate(:page => params["page"].to_i, :per_page => (params["perPage"] || 10).to_i)
      end

      if params["updated_at"]
        updated_at = Time.parse params["updated_at"]
        scope = scope.where("conversations.updated_at > ?", updated_at)
      end

      conversations = scope.select { |conversation|
        conversation.videos.count > 0
      }.map do |conversation|
        conversation_json conversation
      end

      ConversationRead.perform_async(current_user.id)

      success_json data: {conversations: conversations}
    end

    # creates one conversation for each number supplied in the invites params.
    # => each conversation will have a video created from the supplied parts params.
    post '/me/conversations/batch' do
      unless ensure_params(:invites, :parts)
        return error_json 400, msg: "missing required params"
      end

      invites = params["invites"]
      parts = params["parts"]
      conversations = []

      for number in invites
        conversation = nil

        success = Conversation.transaction do
          conversation = current_user.conversations.create(creator: current_user)
          inviter = Hollerback::ConversationInviter.new(current_user, conversation, [number])
          inviter.invite

          video = conversation.videos.create(user: current_user)
          VideoStitchRequest.perform_async(parts, video.id)
        end

        if success
          ConversationCreate.perform_async(current_user.id, conversation.id, [number])
          conversations << conversation
        end
      end

      if conversations.any?
        success_json data: conversations.map {|conversation| conversation_json(conversation) }
      else
        error_json 400, for: conversation, msg: "problem creating conversations"
      end
    end

    # params
    #   invites: array of phone numbers
    post '/me/conversations' do
      unless ensure_params(:invites)
        return error_json 400, msg: "missing invites param"
      end

      invites = params["invites"]
      name = params["name"]
      name = nil if params["name"] == "<null>" #TODO: iOs sometimes sends a null value
      conversation = nil

      success = Conversation.transaction do
        conversation = current_user.conversations.create(creator: current_user, name: name)
        inviter = Hollerback::ConversationInviter.new(current_user, conversation, invites)
        inviter.invite
      end

      if success
        ConversationCreate.perform_async(current_user.id, conversation.id, invites)
      end

      if conversation and conversation.errors.blank?
        success_json data: conversation_json(conversation)
      else
        error_json 400, for: conversation, msg: "problem updating"
      end
    end

    get '/me/conversations/:id' do
      begin
        conversation = current_user.conversations.find(params[:id])
        success_json data: conversation_json(conversation)
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    post '/me/conversations/:id/leave' do
      membership = current_user.memberships.where({
        conversation_id: params[:id]

      }).first
      if membership.destroy
        success_json data: nil
      else
        error_json 400, msg: "conversation could not be deleted"
      end
    end

    get '/me/conversations/:conversation_id/invites' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        success_json data: conversation.invites
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    get '/me/conversations/:conversation_id/members' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        success_json data: conversation.members
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
            scoped_videos = scoped_videos.paginate(:page => params[:page], :per_page => (params["perPage"] || 10))
          end

          videos = scoped_videos.with_read_marks_for(current_user)
          video_json = videos.map do |video|
            video.as_json_for_user current_user
          end

          if params[:page]
            last_page = videos.current_page == videos.total_pages
          end

          success_json({
            data: video_json,
            meta: {
              last_page: last_page
            }
          })
        end
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end
  end
end
