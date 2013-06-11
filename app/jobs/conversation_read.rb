class ConversationRead
  include Sidekiq::Worker

  def perform(user_id)
    current_user = User.find(user_id)

    Keen.publish("conversations:list", {
      user: {id: current_user.id, username: current_user.username}
    })
  end
end
