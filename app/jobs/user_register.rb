class UserRegister
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)

    create_messages(user)
    update_conversation_names(user)

    data = {
      memberships: user.memberships.count
    }
    MetricsPublisher.publish(user, "users:new", data)

    if Sinatra::Base.production?
      Hollerback::SMS.send_message "+13033595357", "#{user.username} #{user.phone_normalized} signed up"
    end

    Hollerback::BMO.say("#{user.username} just signed up")
  end

  private

  def create_messages(user)
    Video.where(:conversation_id => user.conversations.map(&:id)).each do |content|
      sender_membership = Membership.where(conversation_id: content.conversation_id, user_id: content.user_id).first
      receiver_membership = Membership.where(conversation_id: content.conversation_id, user_id: user.id).first
      publisher = ContentPublisher.new(sender_membership)

      if !receiver_membership.messages.find_by_guid(content.guid)
        publisher.publish(content, to: [receiver_membership], analytics: false)
      end
    end
  end

  def update_conversation_names(user)
    Membership.where(:conversation_id => user.conversations.map(&:id)).each do |membership|
      membership.update_conversation_name
    end
  end
end
