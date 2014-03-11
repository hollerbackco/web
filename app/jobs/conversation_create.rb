class ConversationCreate
  include Sidekiq::Worker

  def perform(user_id, conversation_id, invites)
    user = User.find(user_id)
    conversation = Conversation.find(conversation_id)

    data = {
      :name => conversation.name,
      :total_invited_count => invites.count,
      :already_users_count => conversation.members.count,
      :conversation_count => user.conversations.count
    }
    MetricsPublisher.publish(user, "conversations:create", data)

    publish_invited(user, conversation)
  end

  private

  def publish_invited(user, conversation)
    phones = conversation.invites.map(&:phone)
    phones.each do |phone|
      data = {
        invited_phone: phone
      }
      MetricsPublisher.publish(user, "users:invite", data)
    end
    if phones.any?
      Hollerback::BMO.say("#{user.username} just invited #{phones.count} people")
    end
  end
end
