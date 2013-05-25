class Device < ActiveRecord::Base
  attr_accessible :platform, :platform_version, :token

  validates :platform, presence: true, inclusion: {in: %w(ios android)}
  validates :token,    presence: true

  belongs_to :user

  def ios?
    platform == "ios"
  end
end
