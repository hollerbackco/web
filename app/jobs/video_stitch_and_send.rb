class VideoStitchAndSend
  include Sidekiq::Worker

  def perform(files, conversation_id, sender_id)
    conversation = Conversation.find(conversation_id)
    user = User.find(sender_id)

    if user and conversation
      video_path = Hollerback::S3Stitcher.new(files, Video::BUCKET_NAME).run

      video = conversation.videos.build(
        user: user,
        filename: video_path
      )

      if video.save
        conversation.touch!
        video.mark_as_read! for: user

        people = conversation.members - [user]

        people.each do |person|
          if person.device_token.present?
            badge_count = person.unread_videos.count
            APNS.send_notification(person.device_token, alert: "#{user.name}", 
                                   badge: badge_count,
                                   sound: "default",
                                   other: {hb: {conversation_id: conversation.id}})
          end
        end
      end
    end
  end
end
