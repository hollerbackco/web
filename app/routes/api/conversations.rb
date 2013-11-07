module HollerbackApp
  class ApiApp < BaseApp
    get '/me/conversations' do
      scope = current_user.memberships
      if params["updated_at"]
        updated_at = Time.parse params["updated_at"]
        scope = scope.where("memberships.updated_at > ?", updated_at)
      end
      memberships = scope

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
        conversation = inviter.conversation

        urls = params.select {|key,value| ["parts", "part_urls", "urls"].include? key }
        unless urls.blank?
          video = conversation.videos.create(user: current_user, guid: params[:guid])
          VideoStitchRequest.perform_async(video.id, urls)
        end
        success_json data: inviter.inviter_membership.as_json
      else
        error_json 400, for: inviter, msg: "conversation could not be created"
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

      messages = membership.messages.unseen
      if params[:watched_ids]
        messages = messages.where(:video_guid => params[:watched_ids])
      end

      if messages.any?
        VideoRead.perform_async(messages.map(&:id), current_user.id)
      end

      ConversationTtyl.perform_async(membership.id)

      MetricsPublisher.delay.publish(current_user.meta, "conversations:ttyl", {
        conversation_id: membership.conversation_id
      })
      success_json data: nil
    end

    post '/me/conversations/:id/leave' do
      membership = current_user.memberships.find(params[:id])
      if membership.leave!
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
