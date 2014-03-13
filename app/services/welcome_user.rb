class WelcomeUser
  attr_accessor :user

  def initialize(user, will=nil)
    @user = user
    @will = will
  end

  def run
    filename = "batch/welcome.mp4"
    send_video_to_user(filename, user)
    begin
      notify_friend_join
    rescue Exception => e
      logger.error e.to_s
    end
  end

  def send_video_to_user(filename, user)
    return unless will_user
    conversation = user.conversations.create
    conversation.name = "Welcome to Hollerback"
    conversation.members << will_user
    conversation.save
    membership = Membership.where(conversation_id: conversation.id, user_id: will_user.id).first

    publisher = ContentPublisher.new(membership)

    video = conversation.videos.create({
      user: will_user,
      filename: filename
    })

    publisher.publish(video, {
      needs_reply: true,
      is_reply: false
    })
  end

  def will_user
    @will ||= User.find_by_username("will_from_hollerback") || User.find_by_username("will")
  end

  def notify_friend_join
    return unless user
    friends = Contact.where(phone_hashed: user.phone_hashed)

    friends.each do |friend|
      msg = "#{friend.name} just joined"
      MetricsPublisher.publish(friend.user, "friends:join")
      Hollerback::Push.delay.send(friend.user.id, {
        alert: msg,
        sound: "default",
        content_available: true,
        data: {uuid: SecureRandom.uuid}
      }.to_json)

      tokens =  friend.user.devices.android.map {|device| device.token}
      payload = {:message => msg}
      if(!tokens.empty?)
        Hollerback::GcmWrapper.send_notification(tokens, Hollerback::GcmWrapper::TYPE::NOTIFICATION, payload)
      end

      Mail.deliver do
        to friend.user.email
        from 'no-reply@hollerback.co'
        subject "#{friend.name} just joined Hollerback"

        text_part do
          body "Just wanted to let you know that #{friend.name} just joined Hollerback! Send them a message."
        end
      end

    end
  end
end
