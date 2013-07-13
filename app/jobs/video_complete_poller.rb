class VideoCompletePoller
  attr_accessor :queue
  def initialize(queue)
    @queue = queue
  end

  def run
    SQSLogger.logger.info " -- Started Video Ready Polling Service"
    queue.poll do |message|
      SQSLogger.logger.info "Message body: #{message.body}"
      data = JSON.parse(message.body)

      if video = Video.find(data["video_id"])
        video.update_attributes(filename: data["output"], in_progress: false)
        video.ready!
        video.conversation.touch
        video.user.memcache_key_touch

        notify_recipients(video)
        publish_analytics(video)
      end

      SQSLogger.logger.info " -- Finshed updating #{video.id}"
    end
  end

  private

  def notify_recipients(video)
    Hollerback::NotifyRecipients.new(video).run
  end

  def publish_analytics(video)
    Keen.publish("video:create", {
      id: video.id,
      receivers_count: (video.conversation.members.count - 1),
      conversation: {
        id: video.conversation.id,
        videos_count: video.conversation.videos.count
      },
      user: {id: video.user.id, username: video.user.username}
    })
  end
end
