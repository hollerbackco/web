module HollerbackApp
  class ApiApp < BaseApp
    before '/me*' do
      authenticate(:api_token)
    end

    get '/' do
      {
        msg: "Hollerback App Api v1"
      }.to_json
    end

    get '/me' do
      { data: current_user.as_json.merge(conversations: current_user.conversations)}.to_json
    end

    post '/me' do
      obj = {}
      obj[:email] = params[:email] if params.key? :email
      obj[:name]  = params[:name] if params.key? :name
      obj[:device_token]  = params[:device_token] if params.key? :device_token
      obj[:phone]  = params[:phone] if params.key? :phone

      if current_user.update_attributes obj
        { data: current_user.as_json.merge(conversations: current_user.conversations)}.to_json
      else
        error_json 400, "problem updating"
      end
    end

    ########################################
    # conversations
    ########################################

    get '/me/conversations' do
      conversations = current_user.conversations.map do |conversation|
        conversation_json conversation
      end

      { data: {conversations: conversations} }.to_json
    end

    # params
    #   invites: array of phone numbers
    post '/me/conversations' do
      conversation = nil

      status = Conversation.transaction do
        conversation = current_user.conversations.create(creator: current_user)
        inviter = Hollerback::ConversationInviter.new(current_user, conversation, params[:invites])

        inviter.invite
      end

      if status
        {
          data: conversation_json(conversation)
        }.to_json
      else
        {errors: "the conversation could not be created"}.to_json
      end
    end

    get '/me/conversations/:id' do
      begin
        conversation = current_user.conversations.find(params[:id])
        {
          data: conversation_json(conversation)
        }.to_json
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    get '/me/conversations/:conversation_id/invites' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        {
          data: conversation.invites
        }.to_json
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    get '/me/conversations/:conversation_id/members' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        {
          data: conversation.members
        }.to_json
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    get '/me/conversations/:conversation_id/videos' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        {
          data: conversation.videos.with_read_marks_for(current_user)
        }.to_json
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end


    ########################################
    # videos
    ########################################

    get '/me/conversations/:conversation_id/videos/:id/user' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        video = conversation.videos.find params[:id]
        {
          data: video.user
        }.to_json
      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end

    post '/me/videos/:id/read' do
      video = Video.find(params[:id])

      if video.mark_as_read! for: current_user
        {
          data: video.with_read_marks_for(current_user)
        }.to_json
      else
        error_json 400, "could not mark as read"
      end
    end

    post '/me/conversations/:id/videos' do
      begin
        conversation = current_user.conversations.find(params[:id])

        video = conversation.videos.build(
          user: current_user,
          filename: params[:filename]
        )

        if video.save
          video.mark_as_read! for: current_user

          people = conversation.members - [current_user]

          people.each do |person|
            if person.device_token.present?
              APNS.send_notification(person.device_token, alert: "#{current_user.name} sent a message", other: {hb: {conversation_id: conversation.id}})
            else
              puts "what the heck"
            end
            Hollerback::SMS.send_message person.phone_normalized, "#{current_user.name} has sent a message"
          end

          {
            data: video
          }.to_json
        else
          error_json 400, "please specify filename: where the file is located"
        end

      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end
  end
end
