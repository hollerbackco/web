class Video < ActiveRecord::Base
  if Sinatra::Base.production?
    BUCKET_NAME = "hollerback-app"
  else
    BUCKET_NAME = "hollerback-app-dev"
  end

  attr_accessible :filename, :user, :conversation, :in_progress
  acts_as_readable :on => :created_at

  belongs_to :user
  belongs_to :conversation

  default_scope order("created_at DESC")

  def ready!
    in_progress = false
    save!
  end

  def url
    #filename
    #"http://s3.amazonaws.com/#{BUCKET_NAME}/#{filename}"
    filename.present? ? video_object.url_for(:read) : ""
  end

  def thumb_url
    #"http://s3.amazonaws.com/#{BUCKET_NAME}/#{thumb}"
    filename.present? ? thumb_object.url_for(:read) : ""
  end

  def thumb
    thumb = filename.split(".").first << "-thumb.png"
  end

  def

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
    options = options.merge(:methods => [:isRead])
    super(options)
  end

  def self.bucket
    @bucket ||= AWS::S3.new.buckets[BUCKET_NAME]
  end

  private

  def video_object
    self.class.bucket.objects[filename]
  end

  def thumb_object
    self.class.bucket.objects[thumb]
  end
end
