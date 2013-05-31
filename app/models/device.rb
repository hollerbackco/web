class Device < ActiveRecord::Base
  attr_accessible :platform, :platform_version, :token

  validates :platform, presence: true, inclusion: {in: %w(ios android general)}
  #validates :token,    presence: true

  belongs_to :user

  scope :ios, where(platform: "ios")
  scope :android, where(platform: "android")
  scope :general, where(platform: "general")

  before_create :set_access_token

  def ios?
    platform == "ios"
  end

  private

  def set_access_token
    self.access_token = loop do
      access_token = ::Hollerback::Random.friendly_token(40)
      break access_token unless Device.find_by_access_token(access_token)
    end
  end
end
