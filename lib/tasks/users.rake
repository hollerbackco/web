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

  desc "create conversations with will_from_hollerback"
  task :welcome do
    filename = "batch/welcome.mp4"
    User.all.each do |user|
      next if Conversation.find_by_members([will_user,user]).any?

      send_video_to_user(filename, user)
    end
  end

  desc "test conversation creation with jeff"
  task :welcome_test do
    filename = "batch/welcome.mp4"
    user = User.find_by_username("jeff")

    send_video_to_user(filename, user)
  end

  def send_video_to_user(filename, user)
    conversation = user.conversations.create
    conversation.members << will_user
    conversation.save
    membership = Membership.where(conversation_id: conversation.id, user_id: will_user.id).first

    publisher = ContentPublisher.new(membership)

    video = conversation.videos.create({
      user: will_user,
      filename: filename
    })

    publisher.publish(video, {
      needs_reply: true,
      is_reply: false
    })
  end

  def will_user
    @will ||= User.find_by_username("will_from_hollerback") || User.find_by_username("will")
  end
end
