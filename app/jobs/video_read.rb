class VideoRead
  include Sidekiq::Worker

  def perform(video_id, user_id)
    current_user = User.find(user_id)

    message = Message.find(video_id)
    message.seen!

    Keen.publish("video:watch", {
      id: video_id,
      user: {id: current_user.id, username: current_user.username} })

    notify_mqtt(message, current_user)

    unwatched_count = current_user.unseen_memberships_count
    current_user.devices.ios.each do |device|
      APNS.send_notification(device.token, badge: unwatched_count)
    end
  end

  private

    def notify_mqtt(message, person)
      MQTT::Client.connect(remote_host: '23.23.249.106', username: "UXiXTS1wiaZ7", password: "G4tkwWMOXa8V") do |c|
        p "send a mqtt push"
        data = [message.to_sync, message.membership.to_sync]
        p data
        c.publish("user/#{person.id}/sync", xtea.encrypt(data.to_json), false, 1)
      end
    end

    def xtea
      key = "8926AEC00DA47334F7A4F0689AA3E6B4"
      @xtea ||= ::Xtea.new(key, 64)
    end
end
