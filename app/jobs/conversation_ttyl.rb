class ConversationTtyl
  include Sidekiq::Worker

  def perform(membership_id)
    membership = Membership.find(membership_id)
    conversation = membership.conversation
    conversation.ttyl

    notify_mqtt(conversation.memberships)

    membership.others do |other|
      p "notify push to #{other.username}"
      notify_push(membership.user.username, other)
    end
  end

  private

  def notify_mqtt(memberships)
    memberships.each do |m|
      channel = "user/#{m.user_id}/sync"
      data = [m.to_sync]

      Hollerback::MQTT.publish(channel, data)
    end
  end

  def notify_push(sender_name,person)
    data = {
      sender_name: sender_name
    }

    text = "#{sender_name} said ttyl"

    person.devices.ios.each do |device|
      APNS.send_notification(device.token, {
        alert: text,
        badge: 0,
        sound: "default",
        other: {
          hb: data
        }
      })
    end

    person.devices.android.each do |device|
      ::GCMS.send_notification([device.token],
        data: data
      )
    end
  end
end
