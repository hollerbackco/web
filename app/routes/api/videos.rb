module HollerbackApp
  class ApiApp < BaseApp
    get '/me/conversations/:conversation_id/videos' do
      begin
        ConversationRead.perform_async(current_user.id)
        membership = current_user.memberships.find(params[:conversation_id])

        messages = membership.messages.where(:message_type => Message::Type::VIDEO).watchable.seen.order("created_at DESC").scoped

        if params[:page]
          messages = messages.paginate(:page => params[:page], :per_page => (params[:perPage] || 10))
          last_page = messages.current_page == messages.total_pages
        end

        begin
          Message.set_message_display_info(messages)
        rescue Exception => e
          logger.error e
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

        messages = membership.messages.(:message_type => Message::Type::VIDEO).seen.scoped

        if params[:page]
          messages = messages.paginate(:page => params[:page], :per_page => (params[:perPage] || 10))
          last_page = messages.current_page == messages.total_pages
        end

        begin
          Message.set_message_display_info(messages)
        rescue Exception => e
          logger.error e
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
      messages = current_user.messages.all_by_guid(params[:id])
      if messages.any?
        messages.each(&:seen!)
        VideoRead.perform_async(messages.map(&:id), current_user.id)
      end
      success_json data: messages.first.as_json
    end

    post '/me/conversations/:id/videos/parts' do
      logger.debug params

      begin
        if !params.key?("parts") and !params.key?("part_urls") and !params.key?("urls")
          return error_json 400, msg: "missing parts param"
        end
        membership = current_user.memberships.find(params[:id])

        # mark messages as read
        messages = membership.messages.unseen.received.watchable
        if params[:watched_ids]
          messages = params[:watched_ids].map do |watched_id|
            logger.debug watched_id
            items = current_user.messages.all_by_guid(watched_id)
            logger.debug items
            items
          end.flatten.compact
          if messages.any?
            messages.each(&:seen!)
            VideoRead.perform_async(messages.map(&:id), current_user.id)
            unread_count = 0
          end
        end

        # create video stich request
        urls = params.select { |key, value| ["urls", "parts", "part_urls"].include? key }

        # check for existence
        video = params.key?("guid") ? Video.find_by_guid(params[:guid].downcase) : nil

        # if it doesnt exist create the video
        if video.blank?
          video = membership.conversation.videos.new({
                                                         user: current_user,
                                                         subtitle: params[:subtitle],
                                                         stitch_request: urls
                                                     })
          if params.key?("guid")
            video.guid = params["guid"]
          end
          video.save
          VideoStitchRequest.perform_async(video.id, urls, params.key?("reply"), params[:needs_reply])
        end

        success_json data: video.as_json.merge(:conversation_id => membership.id)
      rescue ActiveRecord::RecordNotFound => ex
        error_json 400, msg: ex.message
      end
    end

    post '/me/conversations/:id/videos' do
      if !ensure_params(:filename)
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
