class Video < ActiveRecord::Base
  if production?
    BUCKET_NAME = "hollerback-app"
  else
    BUCKET_NAME = "hollerback-app-dev"
  end

  attr_accessible :filename, :user, :conversation

  acts_as_readable :on => :created_at

  belongs_to :user
  belongs_to :conversation

  default_scope order("created_at DESC")

  def url
    video_object.url_for(:read)
  end

  def thumb_url
    thumb_object.url_for(:read)
  end

  def metadata
    video_object.metadata
  end

  def self.video_urls
    bucket.objects.map {|o| o.url_for(:read)}
  end

  def isRead
    self[:read_mark_id].present? and read_mark_id.present?
  end

  def as_json(options={})
    options = options.merge(:methods => [:isRead, :url, :thumb_url])
    super(options)
  end

  def self.bucket
    @bucket ||= AWS::S3.new.buckets[BUCKET_NAME]
  end

  private

  def video_object
    self.bucket.objects[filename]
  end

  def thumb_object
    thumb = filename.split(".").first << "-thumb.png"
    self.bucket.objects[thumb]
  end
end
