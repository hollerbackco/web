require 'digest/md5'
class User < ActiveRecord::Base
  include Hollerback::SecurePassword

  #has_secure_password
  attr_accessible :name, :email, :phone, :phone_hashed, :username,
    :password, :password_confirmation, :phone_normalized,
    :device_token, :last_app_version

  acts_as_reader

  has_many :devices, autosave: true
  has_many :memberships
  has_many :messages, through: :memberships
  has_many :unseen_messages, through: :memberships
  has_many :conversations, through: :memberships
  #has_many :videos, through: :conversations
  #has_many :sent_videos, foreign_key: "user_id", class_name: "Video"
  has_many :contacts

  before_create :set_access_token
  before_create :set_verification_code

  #todo: remove this
  #before_validation :set_username, on: :create

  validates :phone, presence: true, uniqueness: true
  validates :username, presence: true

  #validates :name, presence: true
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

  def member_of
    Conversation.joins(:members).where("users.id" => [self])
  end

  def also_known_as(obj={})
    user = obj[:for]
    contact = user.contacts.where(phone_hashed: phone_hashed).first
    contact.present? ? contact.name : username
  end

  def self.authenticate(phone, code)
    user = User.find_by_phone_normalized(phone)
    if user and user.verify(code)
      user
    else
      nil
    end
  end

  def self.authenticate_with_email(email, password)
    user = User.find_by_email(email).try(:authenticate, password)
  end

  def self.authenticate_with_access_token(access_token)
    if device = Device.find_by_access_token(access_token)
      device.user
    else
      nil
    end
  end

  def phone_hashed
    return self[:phone_hashed] if self[:phone_hashed].present?

    self.phone_hashed = Digest::MD5.hexdigest(phone_normalized)
    save && self.phone_hashed
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


  def verified?
    self.verification_code.blank?
  end
  alias_method :isVerified, :verified?

  def verify(code)
    self.verification_code == code
  end

  def reset_verification_code!
    set_verification_code
    save!
  end

  def verification_code
    if self[:verification_code].blank?
      set_verification_code
      save
    end
    self[:verification_code]
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
    options = options.merge(:only => [:id, :phone, :phone_normalized, :username, :name, :created_at])
    options = options.merge(:methods => [:phone_hashed])
    super(options)
  end

  private

  def phoner
    @phoner ||= Phoner::Phone.parse(phone_normalized)
  end

  def set_access_token
    self.access_token = loop do
      access_token = ::Hollerback::Random.friendly_token(40)
      break access_token unless User.find_by_access_token(access_token)
    end
  end

  def set_verification_code
    self.verification_code = SecureRandom.random_number(8999) + 1000
  end
end
