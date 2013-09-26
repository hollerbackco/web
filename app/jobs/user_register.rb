class UserRegister
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)

    Invite.accept_all!(user)

    create_messages(user)
    update_conversation_names(user)

    Keen.publish("users:new", {
      memberships: user.conversations.count
    })

    if Sinatra::Base.production?
      Hollerback::SMS.send_message "+13033595357", "#{user.username} #{user.phone_normalized} signed up"
    end

    Hollerback::SMS.send_message user.phone_normalized, "Verification Code: #{user.verification_code}"
  end

  private

  def create_messages(user)
    Video.where(:conversation_id => user.conversations.select(:id)).each do |content|
      sender_membership = Membership.where(conversation_id: content.conversation_id, user_id: content.user_id).first
      receiver_membership = Membership.where(conversation_id: content.conversation_id, user_id: user.id).first
      publisher = ContentPublisher.new(sender_membership)
      publisher.publish(content, to: receiver_membership, analytics: false)
    end
  end

  def update_conversation_names(user)
    user.conversations.each do |membership|
      membership.update_conversation_name
    end
  end
end
