module HollerbackApp
  class ApiApp < BaseApp
    before '/me*' do
      authenticate(:api_token)
    end

    before '/contacts*' do
      authenticate(:api_token)
    end

    not_found do
      {
        meta: {
          code: 404,
          msg: "not found",
          errors: []
        },
        data: nil
      }.to_json
    end

    get '/' do
      {
        msg: "Hollerback App Api v1"
      }.to_json
    end

    get '/contacts/check' do
      numbers = params["numbers"]
      contact_checker =  Hollerback::ContactChecker.new(numbers, current_user)
      {
        meta: {
          code: 200
        },
        data: contact_checker.contacts
      }.to_json
    end

    get '/me' do
      {
        meta: {
          code: 200
        },
        data: current_user.as_json.merge(conversations: current_user.conversations)
      }.to_json
    end

    post '/me' do
      obj = {}
      obj[:email] = params["email"] if params.key? "email"
      obj[:name]  = params["name"] if params.key? "name"
      obj[:device_token]  = params["device_token"] if params.key? "device_token"
      obj[:phone]  = params["phone"] if params.key? "phone"

      if current_user.update_attributes obj
        {
          meta: {
            code: 200
          },
          data: current_user.as_json.merge(conversations: current_user.conversations)
        }.to_json
      else
        error_json 400, msg: current_user
      end
    end

    post '/me/verify' do
      if current_user.verify! params["code"]
        {
          meta: {
            code: 200
          },
          data: current_user.as_json.merge(conversations: current_user.conversations)
        }.to_json
      else
        error_json 400, msg: "incorrect code"
      end
    end

    ########################################
    # conversations
    ########################################

    get '/me/conversations' do
      conversations = current_user.conversations.map do |conversation|
        conversation_json conversation
      end

      Keen.publish("conversations:list", {
        user: {
          id: current_user.id,
          username: current_user.username
        }
      })

      {
        meta: {
          code: 200
        },
        data: {
          conversations: conversations
        }
      }.to_json
    end

    # params
    #   invites: array of phone numbers
    post '/me/conversations' do
      unless ensure_params :invites
        return error_json 400, msg: "missing invites param"
      end

      unless conversation = Conversation.find_by_phone_numbers(current_user, params[:invites])
        success = Conversation.transaction do
          conversation = current_user.conversations.create(creator: current_user)
          inviter = Hollerback::ConversationInviter.new(current_user, conversation, params[:invites])
          inviter.invite
        end

        if success
          Keen.publish("conversations:create", {
            :user => {
              id: current_user.id,
              username: current_user.username
            },
            :total_invited_count => params[:invites].count,
            :already_users_count => conversation.members.count
          })
        end
      end

      if conversation.errors.blank?
        {
          meta: {
            code: 200
          },
          data: conversation_json(conversation)
        }.to_json
      else
        error_json 400, for: conversation, msg: "problem updating"
      end
    end

    get '/me/conversations/:id' do
      begin
        conversation = current_user.conversations.find(params[:id])
        {
          meta: {
            code: 200
          },
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
        error_json 400, msg: "conversation could not be deleted"
      end
    end

    get '/me/conversations/:conversation_id/invites' do
      begin
        conversation = current_user.conversations.find(params[:conversation_id])
        {
          meta: {
            code: 200
          },
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
          meta: {
            code: 200
          },
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
          meta: {
            code: 200
          },
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
          meta: {
            code: 200
          },
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

        if current_user.device_token.present?
          badge_count = current_user.unread_videos.count
          APNS.send_notification(current_user.device_token, badge: badge_count)
        end

        {
          meta: {
            code: 200
          },
          data: video
        }.to_json
      else
        error_json 400, msg: "could not mark as read"
      end
    end

    post '/me/conversations/:id/videos/parts' do
      if !ensure_params :parts
        return error_json 400, msg: "missing parts param"
      end

      conversation = current_user.conversations.find(params[:id])
      video = conversation.videos.create(user: current_user)

      VideoStitchAndSend.perform_async(params[:parts], video.id)

      {
        meta: {
          code: 200
        },
        data: video
      }.to_json
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
          conversation.touch
          video.ready!
          video.mark_as_read! for: current_user

          people = conversation.members - [current_user]
          people.each do |person|
            if person.device_token.present?
              badge_count = person.unread_videos.count
              APNS.send_notification(person.device_token, alert: "#{current_user.name}",
                                     badge: badge_count,
                                     sound: "default",
                                     other: {hb: {conversation_id: conversation.id}})
            end
          end

          #todo: move this to async job
          Keen.publish("video:create", {
            id: video.id,
            conversation: {
              id: conversation.id,
              videos_count: conversation.videos.count
            },
            user: {id: current_user.id, username: current_user.username}
          })

          {
            meta: {
              code: 200
            },
            data: video
          }.to_json
        else
          error_json 400, for: video
        end

      rescue ActiveRecord::RecordNotFound
        not_found
      end
    end
  end
end
