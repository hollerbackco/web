class ConversationTtyl
  include Sidekiq::Worker

  def perform(membership_id)
    membership = Membership.find(membership_id)
    conversation = membership.conversation
    conversation.ttyl

    notify_mqtt(conversation.memberships)

    membership.recipient_memberships do |receiver|
      p "notify push to #{receiver.user.username}"
      notify_push(membership.user.username, receiver)
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

  def notify_push(sender_name, membership)
    data = {
      conversation_id: membership.id,
      sender_name: sender_name
    }

    text = "#{sender_name} said ttyl"
    person = membership.user

    person.devices.ios.each do |device|
      APNS.send_notification(device.token, {
        alert: text,
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
