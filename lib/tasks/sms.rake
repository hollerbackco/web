namespace :sms do
  desc "send an sms to all people who were invited but haven't accepted"
  task :invitees_not_accepted do |t|
    invites = Invite.where(:accepted => false, :notified => false)

    invites.find_each do |invite|
      InviteReminder.perform_async(invite.id)
      sleep 5
    end

  end
end