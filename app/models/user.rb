class User < ActiveRecord::Base
  #has_secure_password
  attr_accessible :name, :email, :phone, :username,
    :password, :password_confirmation, :phone_normalized,
    :device_token

  acts_as_reader

  has_many :devices, autosave: true
  has_many :memberships
  has_many :conversations, through: :memberships
  has_many :videos, through: :conversations
  has_many :sent_videos, foreign_key: "user_id", class_name: "Video"

  before_create :set_access_token
  before_create :set_verification_code

  #todo: remove this
  #before_validation :set_username, on: :create

  validates :phone, presence: true, uniqueness: true
  validates :username, presence: true

  #validates :name, presence: true
  #validates :username, presence: true, uniqueness: true
  #validates :email, presence: true, uniqueness: true
  #validates_format_of :email, with: /.+@.+\..+/i

  def memcache_key_touch
    HollerbackApp::BaseApp.settings.cache.set("user/#{id}/memcache-id", self.memcache_id + 1)
  end

  def memcache_id
    HollerbackApp::BaseApp.settings.cache.fetch("user/#{id}/memcache-id") do
      rand(10)
    end
  end

  def memcache_key
    "user/#{id}-#{memcache_id}"
  end

  def device_for(token, platform)
    if token.blank? and platform.blank?
      gen = devices.general.first
      return gen if gen.present?
    end
    devices.where({
      :platform => (platform || "ios"),
      :token => token
    }).first_or_create
  end

  #todo get rid of this
  def access_token
    devices.general.any? ? devices.general.first.access_token : ""
  end

  def unread_videos
    videos.unread_by(self)
  end

  def member_of
    Conversation.joins(:members).where("users.id" => [self])
  end

  def self.authenticate(phone, code)
    user = User.find_by_phone_normalized(phone)
    if user and user.verify(code)
      user
    else
      nil
    end
  end

  def self.authenticate_with_access_token(access_token)
    if device = Device.find_by_access_token(access_token)
      device.user
    else
      nil
    end
  end

  def phone=(phone)
    self.phone_normalized = Phoner::Phone.parse(phone).to_s
    super
  end

  def phone_area_code
    phoner.present? ? phoner.area_code : "858"
  end

  def phone_country_code
    phoner.present? ? phoner.country_code : "1"
  end

  def phoner
    @phoner ||= Phoner::Phone.parse(phone_normalized)
  end

  def verified?
    self.verification_code.blank?
  end
  alias_method :isVerified, :verified?

  def verify(code)
    self.verification_code == code
  end

  def verify!(code)
    if self.verification_code == code
      self.verification_code = nil
      save!
    end
    verified?
  end

  def as_json(options={})
    #TODO: uncomment when we add this to the signup flow
    options = options.merge(:only => [:id, :phone, :phone_normalized, :username, :created_at, :updated_at])
    options = options.merge(:methods => :isVerified)
    #options = options.merge(:except => [:verification_code, :device_token])
    super(options)
  end

  private

  def set_access_token
    self.access_token = loop do
      access_token = ::Hollerback::Random.friendly_token(40)
      break access_token unless User.find_by_access_token(access_token)
    end
  end

  def set_verification_code
    self.verification_code = SecureRandom.hex(3)
  end
end
