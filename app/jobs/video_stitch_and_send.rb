class VideoStitchAndSend
  include Sidekiq::Worker

  def perform(files, video_id)
    video = Video.find video_id

    if video
      video_path = Hollerback::S3Stitcher.new(files, Video::BUCKET_NAME).run

      if video.update_attributes(filename: video_path)
        conversation = video.conversation
        conversation.touch
        video.mark_as_read! for: video.user

        people = conversation.members - [video.user]

        people.each do |person|
          if person.device_token.present?
            badge_count = person.unread_videos.count
            APNS.send_notification(person.device_token, alert: "#{video.user.name}", 
                                   badge: badge_count,
                                   sound: "default",
                                   other: {hb: {conversation_id: conversation.id}})
          end
        end
      end
    end
  end
end
