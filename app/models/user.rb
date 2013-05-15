class User < ActiveRecord::Base
  has_secure_password
  attr_accessible :name, :email, :phone, :username,
    :password, :password_confirmation, :phone_normalized,
    :device_token

  acts_as_reader

  has_many :memberships
  has_many :conversations, through: :memberships
  has_many :videos, through: :conversations
  has_many :sent_videos, foreign_key: "user_id", class_name: "Video"

  before_create :set_access_token
  before_create :set_verification_code

  #todo: remove this
  before_validation :set_username, on: :create

  validates :name, presence: true
  validates :username, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates_format_of :email, with: /.+@.+\..+/i
  validates :phone, presence: true, uniqueness: true
  validates :phone_normalized, presence: true, uniqueness: true

  def unread_videos
    videos.unread_by(self)
  end

  def set_username
    if self.username.blank? and self.email.present?
      self.username = self.email.split("@").first
    end
  end

  def member_of
    Conversation.joins(:members).where("users.id" => [self])
  end

  def self.authenticate(email, password)
    User.find_by_email(email).try(:authenticate, password)
  end

  def self.authenticate_with_access_token(access_token)
    User.find_by_access_token(access_token)
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

  def verify!(code)
    if self.verification_code == code
      self.verification_code = nil
      save!
    end
    verified?
  end

  def as_json(options={})
    #todo: uncomment when we add this to the signup flow
    #options = options.merge(:methods => :isVerified)
    options = options.merge(:except => [:verification_code, :username])
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
