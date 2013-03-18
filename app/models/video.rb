class Video < ActiveRecord::Base
  BUCKET_NAME = "hollerback-app-dev"
  attr_accessible :filename, :user, :conversation

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

  private

  def self.bucket_objects
    ::AWS::S3::Bucket.objects BUCKET_NAME
  end

  def video_object
    ::AWS::S3::S3Object.find filename, BUCKET_NAME
  end
end
