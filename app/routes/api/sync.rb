module HollerbackApp
  class ApiApp < BaseApp
    get '/me/sync' do
      last_sync_at = Time.now
      updated_at = Time.parse(params[:updated_at]) if params[:updated_at]
      before_last_message_at = Time.parse(params[:before_last_message_at]) if params[:before_last_message_at]

      user_agent = Hollerback::UserAgent.new(request.user_agent)
      count = params[:count] #HollerbackApp::IOS_MAX_SYNC_OBJECTS if user_agent.ios? && @app_version &&  GEM::RUBY_VERSION.new(@app_version) >  GEM::RUBY_VERSION.new('1.1.5')

      sync_objects = []

      #check to see if the key exists in the cache, note, the cached_membership is an array of memberships
      #and the memberships are object representation of the active record object
      cached_memberships = settings.cache.get(Membership.cache_key(current_user.id))

      unless cached_memberships
        cached_memberships = Membership.get_memberships_as_objects(current_user.id)

        #save the cached memberships
        settings.cache.set(Membership.cache_key(current_user.id), cached_memberships)
      end

      logger.debug "cached entities" + cached_memberships.to_s


      memberships, ids = Membership.sync_objects(user: current_user, since: updated_at, before: before_last_message_at, count: count)

      #get the memberships within the cached_memberships (already sorted)


      cached_memberships_copy = Array.new(cached_memberships)

      unless before_last_message_at
        cached_memberships_copy.reverse()
      end


      sync_memberships = cached_memberships_copy.reduce([]) do |filtered, membership|

        if(updated_at)

          if(Date.parse(membership.updated_at) >= Date.parse(updated_at))
            filtered << membership
          end

        elsif(before_last_message_at)

          if(Date.parse(membership.updated_at <= Date.parse(before_last_message_at)))
            filtered << membership
          end

        else
          filtered << membership
        end
      end


      #create the sync objects
      sync_memberships = sync_memberships.map do |membership|
        {
            type: "conversation",
            sync: membership
        }
      end

      sync_objects = sync_objects.concat(sync_memberships)

      #get the messages associated with these memberships
      sync_objects = sync_objects.concat(Message.sync_objects(user: current_user, since: updated_at, before: before_last_message_at, membership_ids: ids))

      #the following operation is a very long running query
      ConversationRead.perform_async(current_user.id)

      data = success_json(
        meta: {
          last_sync_at: last_sync_at
        },
        data: sync_objects.as_json
      )
      data
    end
  end
end
