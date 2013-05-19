class VideoStitchAndSend
  include Sidekiq::Worker

  def perform(files, video_id, s3_output_file=nil)
    video = Video.find video_id

    if video
      if s3_output_file.present?
        s3_output_label = labelify(s3_output_file)
      end

      video_path = Hollerback::S3Stitcher.new(files, Video::BUCKET_NAME, s3_output_label).run

      if video.update_attributes(filename: video_path, in_progress: false)
        video.conversation.touch
        video.mark_as_read! for: video.user
        notify_recipients(video)
        publish_analytics(video)
      end
    end
  end

  private

  #removes extension
  def labelify(filename)
     filename.split(".").first
  end

  def notify_recipients(video)
      recipients = video.conversation.members - [video.user]
      recipients.each do |person|
        if person.device_token.present?
          badge_count = person.unread_videos.count
          APNS.send_notification(person.device_token, alert: "#{video.user.name}",
            badge: badge_count,
            sound: "default",
            other: {
              hb: {
                conversation_id: video.conversation.id,
                video_id: video.id
              }
          })
        end
      end
  end

  def publish_analytics(video)
    Keen.publish("video:create", {
      id: video.id,
      conversation: {
        id: video.conversation.id,
        videos_count: video.conversation.videos.count
      },
      user: {id: video.user.id, username: video.user.username}
    })
  end
end
