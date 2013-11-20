class VideoRead
  include Sidekiq::Worker

  def perform(message_ids, user_id, watched_at=nil)
    current_user = User.find(user_id)
    messages = Message.find(message_ids)

    read_messages(messages)

    notify_analytics(messages, current_user)
    #notify_mqtt(messages, current_user)
    #notify_gcm(messages, current_user)
    #notify_apns(current_user)
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
          content_guid: message.guid
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

    def notify_gcm(messages, person)
      data = messages.map(&:to_sync)
      person.devices.android.each do |device|
        ::GCMS.send_notification([device.token], data: data)
      end
    end

    def notify_apns(current_user)
      unwatched_count = current_user.reload.unseen_memberships_count
      current_user.devices.ios.each do |device|
        Hollerback::Push.send(device.token,{
          badge: unwatched_count,
          data: {uuid: SecureRandom.uuid}
        })
      end
    end
end
