class UserRegister
  include Sidekiq::Worker

  def perform(user_id)
    user = User.find(user_id)

    Invite.accept_all!(user)

    create_messages(user)

    Keen.publish("users:new", {
      memberships: user.conversations.count
    })

    if Sinatra::Base.production?
      Hollerback::SMS.send_message "+13033595357", "#{user.username} #{user.phone_normalized} signed up"
    end

    Hollerback::SMS.send_message user.phone_normalized, "Verification Code: #{user.verification_code}"
  end

  private

  def receive_messages(user)
    Video.where(:conversation_id => user.conversations.select(:id)).each do |content|
      publisher = ContentPublisher.new(content.user)
      publisher.publish(content, to: user, analytics: false)
    end
  end
end
