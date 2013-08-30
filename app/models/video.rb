class Video < ActiveRecord::Base
  if Sinatra::Base.production?
    BUCKET_NAME = "hollerback-app-dev"
    CLOUDFRONT_URL = "http://d2qyqd6d7y0u0k.cloudfront.net"
  else
    BUCKET_NAME = "hollerback-app-dev"
    CLOUDFRONT_URL = "http://d2qyqd6d7y0u0k.cloudfront.net"
  end

  attr_accessible :filename, :user, :conversation, :in_progress
  #acts_as_readable :on => :created_at

  belongs_to :user
  belongs_to :conversation

  default_scope order("created_at DESC")

  def self.random_label
    "#{SecureRandom.hex(1).upcase}/#{SecureRandom.uuid.upcase}"
  end

  # prepare the video
  def ready!
    self.in_progress = false
    save!
  end

  def recipients
    return [] if conversation.blank?
    conversation.members - [user]
  end

  def url
    return "" if filename.blank?
    #HollerbackApp::BaseApp.settings.cache.fetch("video-url-#{id}", 1.week) do
    #video_object.public_url
    [CLOUDFRONT_URL, video_object.key].join("/")
    #end
  end

  def thumb_url
    return "" if filename.blank?
    #return "" unless thumb_object.exists?

    #HollerbackApp::BaseApp.settings.cache.fetch("video-thumb-url-#{id}", 1.week) do
    [CLOUDFRONT_URL, thumb_object.key].join("/")
    #end
  end

  def metadata
    video_object.metadata
  end

  def content_hash
    {
      url: url,
      thumb_url: thumb_url
    }
  end

  def self.video_urls
    bucket.objects.map {|o| o.url_for(:read)}
  end

  def as_json(options={})
    options = options.merge(:methods => [:url, :thumb_url])
    super(options)
  end

  def self.bucket_by_name(name)
    AWS::S3.new.buckets[name]
  end

  def self.bucket
    @bucket ||= AWS::S3.new.buckets[BUCKET_NAME]
  end

  private

  def video_object
    self.class.bucket.objects[filename]
  end

  def thumb_object
    thumb = filename.split(".").first << "-thumb.png"
    self.class.bucket.objects[thumb]
  end
end
