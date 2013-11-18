class RemindInvite
  def self.run(dryrun=false)
    self.invites do |invite|
      reminderer = self.new(invite, dryrun)
    end
  end


  attr_accessor :dryrun, :user, :invite, :invited_user
  def initialize(invite,dryrun=false)
    @dryrun = dryrun
    @invite = invite
    @user = invite.user
    @invited_user = User.find_by_phone_normalized(invite.phone)
  end

  def remind
    if remindable?
      message = "#{user.username} sent you a video on hollerback. download it here: www.hollerback.co/download"
      if send_sms(invite.phone, message)
        mark_invited(invite)
        mark_keen_invite(user, invite)
      end
      true
    else
      false
    end
  end

  def send_sms(phone, message)
    p message
    return false if dryrun
    Hollerback::SMS.send_message phone, message
    true
  end

  def remindable?
    return false if invited_user.present?
  end

  private

  def data(invite)
    key = "invite:#{invite.id}:push_invited"
    REDIS.get(key)
  end

  def mark_invited(invite)
    key = "invite:#{invite.id}:push_invited"
    data = ::MultiJson.encode({invite: invite.id, sent_at: Time.now})
    REDIS.set(key, data)
  end

  def mark_keen_invite(user, invite)
    MetricsPublisher.publish(user, "push:invite_reminder", {invite_id: invite.id, phone: invite.phone})
  end

  def self.invites
    time = Time.now - 3.days
    Invite.pending.where("invites.created_at < ?", time).uniq { |invite| invite.phone }
  end
end
