class ConversationCreate
  include Sidekiq::Worker

  def perform(user_id, conversation_id, invites)
    user = User.find(user_id)
    conversation = Conversation.find(conversation_id)

    Keen.publish("conversations:create", {
      :name => conversation.name,
      :user => {
        id: user.id,
        username: user.username
      },
      :total_invited_count => params[:invites].count,
      :already_users_count => conversation.members.count
    })
  end
end
