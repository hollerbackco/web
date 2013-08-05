module HollerbackApp
  class ApiApp < BaseApp
    get '/me/conversations/:conversation_id/videos/:id/user' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        video = conversation.videos.find params[:id]

        success_json data: video.user
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    post '/me/videos/:id/read' do
      video = Video.find(params[:id])
      video.mark_as_read! for: current_user
      conversation = video.conversation

      #TODO make sure this doesnt get reset before video is marked as read.
      current_user.memcache_key_touch
      key = "user/#{current_user.id}/conversations/#{conversation.id}-#{conversation.updated_at}"
      HollerbackApp::BaseApp.settings.cache.delete key
      VideoRead.perform_async(video.id, current_user.id)

      success_json data: video.as_json_for_user(current_user).merge(conversation: conversation_json(conversation))
    end

    post '/me/conversations/:id/videos/parts' do
      if !ensure_params :parts
        return error_json 400, msg: "missing parts param"
      end

      conversation = current_user.conversations.find(params[:id])
      video = conversation.videos.create(user: current_user)

      VideoStitchRequest.perform_async(params[:parts], video.id)

      success_json data: video
    end

    post '/me/conversations/:id/videos' do
      if !ensure_params :filename
        return error_json 400, msg: "missing filename param"
      end

      begin
        conversation = current_user.conversations.find(params[:id])
        video = conversation.videos.build(
          user: current_user,
          filename: params[:filename]
        )

        if video.save
          video.ready!
          conversation.touch
          current_user.memcache_key_touch
          Hollerback::NotifyRecipients.new(video).run

          #todo: move this to async job
          Keen.publish("video:create", {
            id: video.id,
            receivers_count: (conversation.members.count - 1),
            conversation: {
              id: conversation.id,
              videos_count: conversation.videos.count
            },
            user: {id: current_user.id, username: current_user.username}
          })

          success_json data: video.as_json_for_user(current_user)
        else
          error_json 400, for: video
        end

      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end
  end
end
