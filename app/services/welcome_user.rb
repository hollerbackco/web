class WelcomeUser
  attr_accessor :user

  def initialize(user, will=nil)
    @user = user
    @will = will
  end

  def run
    filename = "batch/welcome.mp4"
    send_video_to_user(filename, user)
    notify_friend_join
  end

  def send_video_to_user(filename, user)
    conversation = user.conversations.create
    conversation.name = "Welcome to Hollerback"
    conversation.members << will_user
    conversation.name = "Welcome to Hollerback"
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
    friends = Contact.where(phone_hashed: user.phone_hashed).map {|contact| contact.user }.compact
    for friend in friends
      msg = "#{user.username} just joined"
      MetricsPublisher.publish(friend, "friends:join")
      Hollerback::Push.delay.send(friend.id, {
        alert: msg,
        sound: "default",
        content_available: true,
        data: {uuid: SecureRandom.uuid}
      }.to_json)
    end
  end
end
