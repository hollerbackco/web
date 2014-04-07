module HollerbackApp
  class ApiApp < BaseApp
    get '/me/sync' do
      last_sync_at = Time.now
      updated_at = Time.parse(params[:updated_at]) if params[:updated_at]
      before_last_message_at = Time.parse(params[:before_last_message_at]) if params[:before_last_message_at]

      user_agent = Hollerback::UserAgent.new(request.user_agent)
      count = params[:count] #HollerbackApp::IOS_MAX_SYNC_OBJECTS if user_agent.ios? && @app_version &&  GEM::RUBY_VERSION.new(@app_version) >  GEM::RUBY_VERSION.new('1.1.5')

      #get the memberships
      memberships, ids = Membership.sync_objects(user: current_user, since: updated_at, before: before_last_message_at, count: count)
      #get the messages associated with these memberships
      messages = Message.get_objects(user: current_user, since: updated_at, before: before_last_message_at, membership_ids: ids)
      
      sync_objects = count_by_membership_id_and_set_unread(messages, memberships)

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

    private

    def count_by_membership_id_and_set_unread(messages, memberships)
      unless messages.empty?
        groups = messages.group_by(&:membership_id)
        memberships.each do |membership|
          # iterate through the memberships and set the unread_count
          membership[:sync]["unread_count"] = groups[membership[:sync]["id"]].count
        end
      end
      [].concat(memberships).concat(messages.map(&:to_sync))
    end
  end
end
