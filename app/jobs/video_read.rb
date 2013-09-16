class VideoRead
  include Sidekiq::Worker

  def perform(message_ids, user_id)
    current_user = User.find(user_id)
    messages = Message.find(message_ids)

    notify_analytics(messages, current_user)
    notify_mqtt(messages, current_user)
    notify_apns(current_user)
  end

  private

    def read_messages(messages)
      messages.each do |message|
        message.seen!
      end
    end

    def notify_analytics(messages, current_user)
      messages.each do |message|
        Keen.publish("video:watch", {
          id: message.id,
          user: {id: current_user.id, username: current_user.username} })
      end
    end

    def notify_mqtt(messages, person)
      MQTT::Client.connect(remote_host: '23.23.249.106', username: "UXiXTS1wiaZ7", password: "G4tkwWMOXa8V") do |c|
        p "send a mqtt push"
        data = messages.map(&:to_sync)
        data << messages.first.membership.to_sync
        p data
        c.publish("user/#{person.id}/sync", xtea.encrypt(data.to_json), false, 1)
      end
    end

    def notify_apns(current_user)
      unwatched_count = current_user.unseen_memberships_count
      current_user.devices.ios.each do |device|
        APNS.send_notification(device.token, badge: unwatched_count)
      end
    end

    def xtea
      key = "8926AEC00DA47334F7A4F0689AA3E6B4"
      @xtea ||= ::Xtea.new(key, 64)
    end
end
