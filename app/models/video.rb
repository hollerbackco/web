class Video < ActiveRecord::Base
  if Sinatra::Base.production?
    STREAM_BUCKET = "hb-streams"
    BUCKET_NAME = "hollerback-app-dev"
  else
    STREAM_BUCKET = "hb-streams"
    BUCKET_NAME = "hollerback-app-dev"
  end

  attr_accessible :filename, :user, :conversation, :in_progress
  acts_as_readable :on => :created_at

  belongs_to :user
  belongs_to :conversation

  default_scope order("created_at DESC")

  def ready!
    self.in_progress = false
    save!
  end

  def url
    filename.present? ? video_object.url_for(:read, :expires => 1.week, :secure => false).to_s : ""
  end

  def stream_url
    streamname.present? ? stream_object.url_for(:read, :expires => 1.week, :secure => false).to_s : ""
  end

  def image_url
    filename.present? ? image_object.url_for(:read, :expires => 1.week, :secure => false).to_s : ""
  end

  def thumb_url
    filename.present? ? thumb_object.url_for(:read, :expires => 1.week, :secure => false).to_s : ""
  end

  def metadata
    video_object.metadata
  end

  def self.video_urls
    bucket.objects.map {|o| o.url_for(:read)}
  end

  def isRead
    !unread?
    #self[:read_mark_id].present? and read_mark_id.present?
  end

  def as_json_for_user(user)
    as_json.merge(isRead: unread?(user))
  end

  def as_json(options={})
    options = options.merge(:methods => [:url, :thumb_url, :image_url, :stream_url])
    super(options)
  end

  def self.bucket
    @bucket ||= AWS::S3.new.buckets[BUCKET_NAME]
  end

  def self.stream_bucket
    @stream_bucket ||= AWS::S3.new.buckets[STREAM_BUCKET]
  end

  private

  def stream_object
    self.class.stream_bucket.objects[streamname]
  end

  def video_object
    self.class.bucket.objects[filename]
  end

  def thumb_object
    thumb = filename.split(".").first << "-thumb.png"
    self.class.bucket.objects[thumb]
  end

  def image_object
    image = filename.split(".").first << "-image.png"
    self.class.bucket.objects[image]
  end
end
