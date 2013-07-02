class VideoStitchRequest
  include Sidekiq::Worker

  def perform(files, video_id, output_key=nil)
    video = Video.find(video_id)
    if video
      if output_key.present?
        label = labelify(output_key)
      end

      urls = files.map {|key| get_url(key) }.flatten

      queue.send_message({
        parts: urls,
        output: "#{Hollerback::Stitcher::Movie.random_label}",
        video_id: video_id
      }.to_json)
    end
  end

  private

  def get_url(key)
    bucket.objects[key].url_for(:read, :expires => 1.month, :secure => false).to_s
  end

  def bucket
    @bucket ||= AWS::S3.new.buckets[Video::BUCKET_NAME]
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
