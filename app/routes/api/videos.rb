module HollerbackApp
  class ApiApp < BaseApp
    get '/me/conversations/:conversation_id/videos' do
      begin
        ConversationRead.perform_async(current_user.id)
        membership = current_user.memberships.find(params[:conversation_id])

        messages = membership.messages.scoped

        if params[:page]
          messages = messages.paginate(:page => params[:page], :per_page => (params["perPage"] || 10))
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
      p "params:"
      p params

      conversation = current_user.conversations.find(params[:id])
      video = conversation.videos.create(user: current_user)

      urls = if params.key? "parts"
        params[:parts].map do |key|
          Video.bucket.objects[key].url_for(:read, :expires => 1.month, :secure => false).to_s
        end
      elsif params.key? "part_urls"
        params[:part_urls].map do |arn|
          bucket, key = arn.split("/", 2)
          Video.bucket_by_name(bucket).objects[key].url_for(:read, :expires => 1.month, :secure => false).to_s
        end
      else
        return error_json 400, msg: "missing parts param"
        []
      end

      VideoStitchRequest.perform_async(urls, video.id)

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
          p video.as_json

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
