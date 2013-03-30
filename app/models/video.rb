class Video < ActiveRecord::Base
  BUCKET_NAME = "hollerback-app-dev"
  attr_accessible :filename, :user, :conversation

  acts_as_readable :on => :created_at

  belongs_to :user
  belongs_to :conversation

  def url
    video_object.url
  end

  def metadata
    video_object.metadata
  end

  def self.video_urls
    bucket_objects.map {|o| o.url}
  end

  def isRead
    self[:read_mark_id].present? and read_mark_id.present?
  end

  def as_json(options={})
    options = options.merge(:methods => :isRead)
    super(options)
  end

  private

  def self.bucket_objects
    ::AWS::S3::Bucket.objects BUCKET_NAME
  end

  def video_object
    ::AWS::S3::S3Object.find filename, BUCKET_NAME
  end
end
