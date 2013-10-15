class VideoStitchRequest
  include Sidekiq::Worker

  def perform(video_id, obj={}, reply=false, needs_reply=true)
    video = Video.find(video_id)
    urls = fetch_urls(obj)

    if video
      # stitcher will send a complete message with the same data
      queue.send_message({
        parts: urls,
        output: "#{Video.random_label}",
        video_id: video_id,
        reply: reply,
        needs_reply: needs_reply
      }.to_json)
    end
  end

  private

  def fetch_urls(urls)
    if urls.key? "parts"
      urls["parts"].map do |key|
        Video.bucket.objects[key].url_for(:read, :expires => 1.month, :secure => false).to_s
      end
    elsif urls.key? "part_urls"
      urls["part_urls"].map do |arn|
        bucket, key = arn.split("/", 2)
        Video.bucket_by_name(bucket).objects[key].url_for(:read, :expires => 1.month, :secure => false).to_s
      end
    end
  end


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
