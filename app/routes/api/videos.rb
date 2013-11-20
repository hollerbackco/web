module HollerbackApp
  class ApiApp < BaseApp
    get '/me/conversations/:conversation_id/videos' do
      begin
        ConversationRead.perform_async(current_user.id)
        membership = current_user.memberships.find(params[:conversation_id])

        messages = membership.messages.order("created_at DESC").scoped

        if params[:page]
          messages = messages.paginate(:page => params[:page], :per_page => (params[:perPage] || 10))
          last_page = messages.current_page == messages.total_pages
        end

        success_json({
          data: messages.as_json,
          meta: {
            last_page: last_page
          }
        })
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    get '/me/conversations/:conversation_id/history' do
      begin
        ConversationRead.perform_async(current_user.id)
        membership = current_user.memberships.find(params[:conversation_id])

        messages = membership.messages.seen.scoped

        if params[:page]
          messages = messages.paginate(:page => params[:page], :per_page => (params[:perPage] || 10))
          last_page = messages.current_page == messages.total_pages
        end

        success_json({
          data: messages.as_json,
          meta: {
            last_page: last_page
          }
        })
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    post '/me/videos/:id/read' do
      message = Message.find(params[:id])
      message.seen!

      VideoRead.perform_async([message.id], current_user.id)

      success_json data: message.as_json
    end

    post '/me/conversations/:id/videos/parts' do
      if !params.key?("parts") and !params.key?("part_urls") and !params.key?("urls")
        return error_json 400, msg: "missing parts param"
      end
      membership = current_user.memberships.find(params[:id])

      #mark messages as read
      messages = membership.messages.unseen
      if params[:watched_ids]
        messages = params[:watched_ids].map do |watched_id|
          current_user.messages.find_by_guid(watched_id)
        end.flatten
        if messages.any?
          VideoRead.perform_async(messages.map(&:id), current_user.id)
          unread_count = 0
        end
      elsif params.key?("reply")
        if params[:watched_at]
          watched_at = Time.parse(params[:watched_at])
          messages = messages.before(watched_at)
        end
        if messages.any?
          VideoRead.perform(messages.map(&:id), current_user.id)
          unread_count = 0
        end
      end

      video = membership.conversation.videos.create({
        user: current_user,
        guid: params[:guid],
        subtitle: params[:subtitle]
      })

      urls = params.select {|key,value| ["urls", "parts", "part_urls"].include? key }

      VideoStitchRequest.perform_async(video.id, urls, params.key?("reply"), params[:needs_reply])

      success_json data: video.as_json.merge(:conversation_id => membership.id, :unread_count => (unread_count || messages.count))
    end

    post '/me/conversations/:id/videos' do
      if !ensure_params :filename
        return error_json 400, msg: "missing filename param"
      end

      begin
        # the id sent in the url is a reference to the users meembership model
        membership = current_user.memberships.find(params[:id])
        conversation = membership.conversation

        # generate the piece of content
        video = Video.new(
          user: current_user,
          conversation: conversation,
          filename: params[:filename]
        )

        if video.save
          publisher = ContentPublisher.new(membership)
          publisher.publish(video)

          success_json data: publisher.sender_message.as_json
        else
          error_json 400, for: video
        end

      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end
  end
end
