class ConversationTtyl
  include Sidekiq::Worker

  def perform(membership_id)
    membership = Membership.find(membership_id)
    membership.ttyl

    conversation = membership.conversation

    notify_mqtt(conversation.memberships)
    membership.others.each do |other|
      p "notify push to #{other.username}"
      notify_push(membership.user.also_known_as(for: other), other)
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
    text = "#{sender_name}: ttyl"

    person.devices.ios.each do |device|
      Hollerback::Push.send(device.token, {
        alert: text,
        sound: "default",
      })
    end

    person.devices.android.each do |device|
      ::GCMS.send_notification([device.token],
        data: data
      )
    end
  end
end
