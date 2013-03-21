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


    ########################################
    # conversations
    ########################################

    get '/me/conversations' do

      conversations = current_user.conversations.map do |conversation|
        conversation.as_json(root: false).merge(
          members: conversation.members,
          invites: conversation.invites,
          videos: conversation.videos
        )
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
          data: conversation.as_json(root: false).merge(
            members: conversation.members,
            invites: conversation.invites,
            videos: conversation.videos
          )
        }.to_json
      else
        {errors: "the conversation could not be created"}.to_json
      end
    end

    get '/me/conversations/:id' do
      begin
        conversation = current_user.conversations.find(params[:id])
        {
          data: conversation.as_json(root: false).merge(
            members: conversation.members,
            invites: conversation.invites,
            videos: conversation.videos
          )
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
          data: conversation.videos
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

    post '/me/conversations/:id/videos' do
      if ensure_params(:id, :filename)
        begin
          conversation = current_user.conversations.find(params[:id])

          conversation.videos.create(
            user: current_user,
            filename: params[:filename]
          )

          {
            data: video
          }.to_json
        rescue ActiveRecord::RecordNotFound
          not_found
        end
      else
        error_json 400, "please specify filename: where the file is located"
      end
    end
  end
end
