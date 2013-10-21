module HollerbackApp
  class ApiApp < BaseApp
    get '/me/conversations' do
      scope = current_user.memberships

      if params["updated_at"]
        updated_at = Time.parse params["updated_at"]
        scope = scope.where("memberships.updated_at > ?", updated_at)
      end

      memberships = scope

      #conversations = scope.select { |conversation|
        #conversation.videos.count > 0
      #}.map do |conversation|
        #conversation_json conversation
      #end

      ConversationRead.perform_async(current_user.id)

      success_json data: {conversations: memberships.as_json}
    end

    # params
    #   invites: array of phone numbers
    post '/me/conversations' do
      unless ensure_params(:invites)
        return error_json 400, msg: "missing invites param"
      end

      invites = params["invites"]
      if invites.is_a? String
        invites = invites.split(",")
      end

      name = params["name"]
      name = nil if params["name"] == "<null>" #TODO: iOs sometimes sends a null value

      inviter = Hollerback::ConversationInviter.new(current_user, invites, name)

      if inviter.invite
        urls = params.select {|key,value| ["parts", "part_urls"].include? key }
        unless urls.blank?
          video = inviter.conversation.videos.create(user: current_user)
          VideoStitchRequest.perform_async(video.id, urls)
        end
        success_json data: inviter.inviter_membership.as_json
      else
        error_json 400, for: inviter, msg: "problem updating"
      end
    end

    # creates one conversation for each number supplied in the invites params.
    # => each conversation will have a video created from the supplied parts params.
    post '/me/conversations/batch' do
      unless ensure_params(:invites, :parts)
        return error_json 400, msg: "missing required params"
      end

      invites = params["invites"]
      if invites.is_a? String
        invites = invites.split(",")
      end

      parts = params["parts"]
      inviter = nil
      memberships = []

      for number in invites
        success = Conversation.transaction do
          inviter = Hollerback::ConversationInviter.new(current_user, [number])
          inviter.invite

          video = inviter.conversation.videos.create(user: current_user)
          VideoStitchRequest.perform_async(parts, video.id)
        end

        memberships << inviter.inviter_membership if success
      end

      if memberships.any?
        success_json data: memberships.as_json
      else
        error_json 400, msg: "problem creating conversations"
      end
    end

    get '/me/conversations/:id' do
      begin
        membership = current_user.memberships.find(params[:id])
        success_json data: membership.as_json.merge(members: membership.members, invites: membership.invites)
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    post '/me/conversations/:id/goodbye' do
      membership = current_user.memberships.find(params[:id])

      if params[:watched_ids]
        messages = membership.messages.where(:video_guid => params[:watched_ids])
        if messages.any?
          VideoRead.perform_async(messages.map(&:id), current_user.id)
          unread_count = messages.count
        end
      end

      membership.conversation.ttyl

      MetricsPublisher.delay.publish(current_user.meta, "conversations:ttyl")
      success_json data: nil
    end

    post '/me/conversations/:id/leave' do
      membership = current_user.memberships.find(params[:id])
      if membership.destroy
        MetricsPublisher.delay.publish(current_user.meta, "conversations:leave")
        success_json data: nil
      else
        error_json 400, msg: "conversation could not be deleted"
      end
    end

    post '/me/conversations/:id/watch_all' do
      membership = current_user.memberships.find(params[:id])
      membership.view_all
      success_json data: nil
    end

    get '/me/conversations/:id/invites' do
      begin
        membership = current_user.memberships.find(params[:id])
        success_json data: membership.invites
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    get '/me/conversations/:id/members' do
      begin
        membership = current_user.memberships.find(params[:id])
        success_json data: membership.members
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end
  end
end
