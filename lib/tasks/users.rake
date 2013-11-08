namespace :users do
  desc "cleanup users that have not been verified in one day"
  task :cleanup do
    signed_up = Time.now - 3.days
    users = User.where("created_at < ?", signed_up).unverified
    users.each do |u|
      MetricsPublisher.publish(user, "users:cleaned")
    end
    p users.destroy_all
  end

  desc "push notification reminder"
  task :push_remind do
    day_ago = Time.now - 1.day
    User.find_each do |user|
      next if user.active?
      message = user.messages
        .unseen
        .received
        .reorder("messages.sent_at DESC")
        .first
      if message.blank?
        p "skip this user"
        next
      end

      badge_count = user.unseen_memberships_count
      user.devices.ios.each do |device|
        p device.token, message.sender_name
        unless ENV['dryrun']
          p "doing the real thing"
          Hollerback::Push.send(device.token, {
            alert: message.sender_name,
            badge: badge_count,
            sound: "default",
            content_available: true
          })
        end
      end
      mark_pushed(user, message)
    end
  end

  def mark_pushed(user, message)
    key = "user:#{user.id}:push_remind"
    data = ::MultiJson.encode({message_id: message.id, sent_at: Time.now})
    REDIS.set(key, data)
  end
end
