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
end
