class TrackInvites
  include Sidekiq::Worker

  def perform(user_id, phones)
    user = User.find(user_id)

    untracked_invites = Invite.where("phone IN (?) AND inviter.id = ? AND tracked = ?", phones, user_id, false)

    actual_invites = []
    untracked_invites.each do |invite|
      unless Invite.where("phone = ?", invite.phone)
        actual_invites << invite.phone
      end
      invite.tracked = true
      invite.save
    end

    data = {
        invites: actual_invites,
        already_invited: (phones - actual_invites)
    }
    MetricsPublisher.publish(user, "users:invite:implicit", data)

  end
end