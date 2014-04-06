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
        needs_reply: (needs_reply || true)
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
    elsif urls.key? "urls"
      urls["urls"]
    end
  end


  def queue
    @queue ||= if ENV["RACK_ENV"] == 'production'
      AWS::SQS.new.queues.create("video-stitch")
    elsif ENV["RACK_ENV"] == 'staging'
      AWS::SQS.new.queues.create("video-stitch-dev")
    elsif ENV["RACK_ENV"] == 'local' || ENV["RACK_ENV"] == 'test'
      AWS.config(
          :use_ssl => false,
          :sqs_endpoint => "localhost",
          :sqs_port => ENV["LOCAL_SQS_PORT"],
          :access_key_id =>  ENV["AWS_ACCESS_KEY_ID"],
          :secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"]
      )
      begin
        return AWS::SQS.new.queues.named("video-stitch-local")
      rescue Exception => e
        return AWS::SQS.new.queues.create("video-stitch-local")
      end
    else
      raise "What environment are you working in? Needs to be one of ('production', 'staging', 'local', 'test')"
    end
  end

  #removes extension
  def labelify(filename)
     filename.split(".").first
  end
end
