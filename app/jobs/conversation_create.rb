class ConversationCreate
  include Sidekiq::Worker

  def perform(user_id, conversation_id, invites)
    user = User.find(user_id)
    conversation = Conversation.find(conversation_id)

    data = {
      :name => conversation.name,
      :total_invited_count => invites.count,
      :already_users_count => conversation.members.count
    }
    MetricsPublisher.publish(user, "conversations:create", data)

    publish_invited(user, conversation)
  end

  private

  def publish_invited(user, conversation)
    conversation.invites.each do |invite|
      data = {
        invited_phone: invite.phone
      }
      MetricsPublisher.publish(user, "users:invite", data)
    end
  end
end
