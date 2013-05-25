class Device < ActiveRecord::Base
  attr_accessible :platform, :platform_version, :token

  validates :platform, presence: true, inclusion: {in: %w(ios android)}
  validates :token,    presence: true

  belongs_to :user

  scope :ios, where(platform: "ios")
  scope :android, where(platform: "android")

  def ios?
    platform == "ios"
  end
end
