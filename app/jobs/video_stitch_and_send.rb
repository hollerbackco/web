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
        make_stream(video)
        video.ready!
        video.conversation.touch
        video.mark_as_read! for: video.user
        notify_recipients(video)
        publish_analytics(video)
      end
    end
  end

  private

  def make_stream(video)
    job = Hollerback::ElasticTranscoderRequest.new(video)
    job.run
  end

  #removes extension
  def labelify(filename)
     filename.split(".").first
  end

  def notify_recipients(video)
    Hollerback::NotifyRecipients.new(video).run
  end

  def publish_analytics(video)
    Keen.publish("video:create", {
      id: video.id,
      receivers_count: (video.conversation.members.count - 1 ),
      conversation: {
        id: video.conversation.id,
        videos_count: video.conversation.videos.count
      },
      user: {id: video.user.id, username: video.user.username}
    })
  end
end
