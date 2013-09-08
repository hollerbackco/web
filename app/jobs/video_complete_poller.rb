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
        delivered = HollerbackApp::BaseApp.settings.cache.get("d/#{video.id}") || false
        if !delivered
          video.update_attributes(filename: data["output"], in_progress: false)
          membership = Membership.where(conversation_id: video.conversation_id, user_id: video.user_id).first
          if membership.present?
            publisher = ContentPublisher.new(membership)
            publisher.publish(video)
          end
          HollerbackApp::BaseApp.settings.cache.set("d/#{video.id}", 1)
          SQSLogger.logger.info " -- Finished updating #{video.id}"
        else
          SQSLogger.logger.info " -- Already delivered #{video.id}"
        end
      end
    end
  end
end
