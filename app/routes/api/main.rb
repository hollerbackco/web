module HollerbackApp
  class ApiApp < BaseApp
    before '/me*' do
      authenticate(:api_token)
    end
    before '/contacts*' do
      authenticate(:api_token)
    end

    get '/' do
      {
        msg: "Hollerback App Api v1"
      }.to_json
    end

    get '/contacts/check' do
      numbers = params[:numbers]
      contact_checker =  Hollerback::ContactChecker.new(numbers, current_user)
      {
        data: contact_checker.contacts
      }.to_json
    end

    get '/me' do
      { data: current_user.as_json.merge(conversations: current_user.conversations)}.to_json
    end

    post '/me' do
      obj = {}
      obj[:email] = params["email"] if params.key? "email"
      obj[:name]  = params["name"] if params.key? "name"
      obj[:device_token]  = params["device_token"] if params.key? "device_token"
      obj[:phone]  = params["phone"] if params.key? "phone"

      if current_user.update_attributes obj
        { data: current_user.as_json.merge(conversations: current_user.conversations)}.to_json
      else
        status 400
        error_json 400, "problem updating"
      end
    end

    post '/me/verify' do
      if current_user.verify! params["code"]
        { data: current_user.as_json.merge(conversations: current_user.conversations)}.to_json
      else
        status 400
        error_json 400, "incorrect code"
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
      conversation = Conversation.find_by_phone_numbers(current_user, params[:invites])
      status = Conversation.transaction do
        unless conversation
          conversation = current_user.conversations.create(creator: current_user)
          #conversation.members << current_user

          Keen.publish("conversations:create", {
            :user => {
              id: current_user.id,
              username: current_user.username
            },
            :total_invited_count => params[:invites].count,
            :already_users_count => conversation.members.count
          })


          inviter = Hollerback::ConversationInviter.new(current_user, conversation, params[:invites])

          inviter.invite
        else
          true
        end
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

    post '/me/conversations/:id/leave' do
      membership = current_user.memberships.where({
        conversation_id: params[:id]
      }).first

      if membership.destroy
        {
          meta: {
            code: 200
          },
          data: nil
        }.to_json
      else
        error_json 400, "conversation could not be deleted"
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
        Keen.publish("video:watch", {
          id: video.id,
          user: {id: current_user.id, username: current_user.username} })

        {
          data: video
        }.to_json
      else
        p "error"
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
          Keen.publish("video:create", {
            id: video.id,
            receivers_count: (conversations.members.count - 1 ),
            conversation: {
              id: conversation.id,
              videos_count: conversation.videos.count
            },
            user: {id: current_user.id, username: current_user.username}
          })

          conversation.touch
          video.mark_as_read! for: current_user

          people = conversation.members - [current_user]

          people.each do |person|
            if person.device_token.present?
              badge_count = person.unread_videos.count
              APNS.send_notification(person.device_token, alert: "#{current_user.name} sent a message", 
                                     badge: badge_count,
                                     sound: "default",
                                     other: {hb: {conversation_id: conversation.id}})
            else
              #Hollerback::SMS.send_message person.phone_normalized, "#{current_user.name} has sent a message"
              puts "what the heck"
            end
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
