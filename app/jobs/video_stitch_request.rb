class VideoStitchRequest
  include Sidekiq::Worker

  def perform(urls, video_id, output_key=nil)
    video = Video.find(video_id)
    if video
      if output_key.present?
        label = labelify(output_key)
      end

      queue.send_message({
        parts: urls,
        output: "#{Video.random_label}",
        video_id: video_id
      }.to_json)
    end
  end

  private

  def queue
    @queue ||= if Sinatra::Base.production?
      AWS::SQS.new.queues.create("video-stitch")
    else
      AWS::SQS.new.queues.create("video-stitch-dev")
    end
  end

  #removes extension
  def labelify(filename)
     filename.split(".").first
  end
end
