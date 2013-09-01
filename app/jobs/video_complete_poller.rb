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
        membership = Membership.where(conversation_id: video.conversation_id, user_id: video.user_id).first
        if membership.present?
          publisher = ContentPublisher.new(membership)
          publisher.publish(video)
        end
      end

      SQSLogger.logger.info " -- Finshed updating #{video.id}"
    end
  end
end
