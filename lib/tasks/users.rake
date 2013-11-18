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
    RemindInactive.run(ENV['dryrun'])
  end

  desc "push sms invite reminders"
  task :push_invite do
    time = Time.now - 3.days
    Invite.pending.where("invites.created_at < ?", time).find_each do |invite|
      user = User.find_by_phone_normalized(invite.phone)
      next if user.present?

      message = "#{invite.inviter.username} sent you a video on hollerback. download it here: www.hollerback.co/download"
      p message
      unless ENV['dryrun']
        Hollerback::SMS.send_message invite.phone, message
        mark_invited(invite)
        mark_keen_invite(invite.inviter, invite)
      end
    end
  end

  def mark_invited(invite)
    key = "invite:#{invite.id}:push_invited"
    data = ::MultiJson.encode({invite: invite.id, sent_at: Time.now})
    REDIS.set(key, data)
  end

  def mark_keen_invite(user, invite)
    MetricsPublisher.publish(user, "push:invite_reminder", {invite_id: invite.id, phone: invite.phone})
  end
end
