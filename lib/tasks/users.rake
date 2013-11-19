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
    RemindInvite.run(ENV['dryrun'])
  end
end
