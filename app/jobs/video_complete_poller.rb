class VideoCompletePoller
  include Celluloid

  attr_accessor :queue

  def initialize(queue)
    @queue = queue
    async.run
  end

  def run
    SQSLogger.logger.info " -- Started Video Ready Polling Service"
    queue.poll do |message|
      SQSLogger.logger.info "Message body: #{message.body}"
      data = JSON.parse(message.body)
      process_message(data)
    end
  end

  def process_message(data)
    if video = Video.find(data["video_id"])
      if !delivered?(video)
        video.update_attributes(filename: data["output"], in_progress: false)
        membership = Membership.where(conversation_id: video.conversation_id, user_id: video.user_id).first
        if membership.present?
          publisher = ContentPublisher.new(membership)
          publisher.publish(video)
        end
        mark_delivered(video)
        SQSLogger.logger.info " -- Finished updating #{video.id}"
      else
        SQSLogger.logger.info " -- Already delivered #{video.id}"
      end
    end
  rescue ActiveRecord::RecordNotFound
    p " -- No video found"
  end

  def delivered?(video)
    delivered = HollerbackApp::BaseApp.settings.cache.get("d/#{video.id}") || false
  end

  def mark_delivered(video)
    HollerbackApp::BaseApp.settings.cache.set("d/#{video.id}", 1)
  end
end
