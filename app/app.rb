module HollerbackApp
  class Main < BaseApp
    before do
      authenticate(:api_token)
    end

    get '/' do
      {
        msg: "Hollerback App Api v1"
      }.to_json
    end

    get '/me' do
      current_user.as_json.merge(conversations: current_user.conversations).to_json
    end


    ########################################
    # conversations
    ########################################

    get '/me/conversations' do
      authenticate(:api_token)
      { conversations: current_user.conversations }.to_json
    end

    # params
    #   invites: array of phone numbers
    post '/me/conversations' do
      status = Conversation.transaction do
        conversation = current_user.conversations.create(creator: current_user)
        inviter = Hollerback::ConversationInviter.new current_user, conversation, params[:invites])

        inviter.invite
      end

      if status
        conversation.to_json
      else
        {errors: "the conversation could not be created"}.to_json
      end
    end

    get '/me/conversations/:id' do
      begin
        conversation = current_user.conversations.find(params[:id])
        {
          conversations: {
            members: conversation.members,
            invites: conversation.invites,
            videos: conversation.videos
          }
        }.to_json
      rescue
        not_found
      end
    end


    ########################################
    # videos
    ########################################

    post '/me/conversations/:id/video' do
      {
      }
    end
  end
end
