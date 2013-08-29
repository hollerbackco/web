class VideoRead
  include Sidekiq::Worker

  def perform(video_id, user_id)
    current_user = User.find(user_id)

    Keen.publish("video:watch", {
      id: video_id,
      user: {id: current_user.id, username: current_user.username} })

    unwatched_count = current_user.messages.unseen.count
    current_user.devices.ios.each do |device|
      APNS.send_notification(device.token, badge: unwatched_count)
    end
  end
end
