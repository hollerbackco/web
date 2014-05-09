namespace :sms do
  desc "send an sms to all people who were invited but haven't accepted"
  task :invitees_not_accepted do |t|
    invites = Invite.where(:accepted => false)

    invites.find_each do |invite|
      InviteReminder.perform_async(invite.id)
    end

  end
end