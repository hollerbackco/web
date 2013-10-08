class VideoRead
  include Sidekiq::Worker

  def perform(message_ids, user_id, watched_at=nil)
    current_user = User.find(user_id)
    messages = Message.find(message_ids)

    read_messages(messages)

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
        data = {
          message_id: message.id,
          content_id: message.content_guid.to_i
        }
        MetricsPublisher.publish(current_user, "video:watch", data)
      end
    end

    def notify_mqtt(messages, person)
      channel = "user/#{person.id}/sync"
      data = messages.map(&:to_sync)
      #is out of sync with stitcher
      #data << messages.first.membership.to_sync
      Hollerback::MQTT.publish(channel, data)
    end

    def notify_apns(current_user)
      unwatched_count = current_user.unseen_memberships_count
      current_user.devices.ios.each do |device|
        APNS.send_notification(device.token, badge: unwatched_count)
      end
    end
end
