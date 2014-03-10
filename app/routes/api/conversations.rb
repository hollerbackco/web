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
      if !ensure_params(:invites) and !ensure_params(:username)
        return error_json 400, msg: "missing invites or username"
      end

      invites = params["invites"]
      if invites.is_a? String
        invites = invites.split(",")
      end

      usernames = params["username"]
      if usernames and usernames.is_a? String
        usernames = usernames.split(",")
      end

      name = params["name"]
      name = nil if params["name"] == "<null>" #TODO: iOs sometimes sends a null value

      inviter = Hollerback::ConversationInviter.new(current_user, invites, usernames, name)

      if inviter.invite
        conversation = inviter.conversation

        urls = params.select {|key,value| ["parts", "part_urls", "urls"].include? key }
        unless urls.blank?
          video = conversation.videos.create(user: current_user, guid: params[:guid])
          VideoStitchRequest.perform_async(video.id, urls)
        end

        #for each of the conversation memberships, insert it into the cache if a cache entry exists
        conversation.memberships.each do |new_membership|
          #add the membership to memcache if a cached entry exists
          cached_memberships = setting.cache.get(Membership.cache_key(new_membership.user_id))

          #add the membership to the cached entry if it exists
          if(cached_memberships)
            cached_memberships.unshift(new_membership.as_json)
          end
        end



        success_json data: inviter.inviter_membership.as_json
      else
        error_json 400, for: inviter, msg: "conversation could not be created"
      end
    end

    get '/me/conversations/:id' do
      begin
        #TODO: look this up from cache if it exists
        membership = current_user.memberships.find(params[:id])
        success_json data: membership.as_json.merge(members: membership.members, invites: membership.invites)
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    post '/me/conversations/:id/goodbye' do
      membership = current_user.memberships.find(params[:id])

      #mark messages as read
      messages = membership.messages.unseen.received.watchable
      if params[:watched_ids]
        messages = params[:watched_ids].map do |watched_id|
          logger.debug watched_id
          items = current_user.messages.all_by_guid(watched_id)
          logger.debug items
          items
        end.flatten.compact
      end
      if messages.any?
        messages.each(&:seen!)
        VideoRead.perform_async(messages.map(&:id), current_user.id)
      end

      # only send ttyl if all videos have been watched
      if membership.reload.messages.unseen.received.watchable.empty?
        ConversationTtyl.perform_async(membership.id)
      end

      MetricsPublisher.publish(current_user, "conversations:ttyl", {
        conversation_id: membership.conversation_id
      })
      success_json data: nil
    end

    post '/me/conversations/:id/leave' do
      membership = current_user.memberships.find(params[:id])
      if membership.leave!
        MetricsPublisher.publish(current_user, "conversations:leave")
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
