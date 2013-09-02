module HollerbackApp
  class ApiApp < BaseApp
    get '/me/conversations/:conversation_id/videos' do
      begin
        ConversationRead.perform_async(current_user.id)
        membership = current_user.memberships.find(params[:conversation_id])

        messages = membership.messages.scoped

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

      VideoRead.perform_async(message.id, current_user.id)

      success_json data: message.as_json
    end

    post '/me/conversations/:id/videos/parts' do
      if !params.key?("parts") and !params.key?("part_urls") 
        return error_json 400, msg: "missing parts param"
      end
      urls = params.select {|key,value| ["parts", "part_urls"].include? key }

      membership = current_user.memberships.find(params[:id])
      video = membership.conversation.videos.create(user: current_user)

      VideoStitchRequest.perform_async(video.id, urls)

      success_json data: video
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
