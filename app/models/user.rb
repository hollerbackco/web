class User < ActiveRecord::Base
  has_secure_password
  attr_accessible :name, :email, :phone,
    :password, :password_confirmation, :phone_normalized

  has_many :memberships
  has_many :conversations, through: :memberships

  before_create :set_access_token

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates_format_of :email, with: /.+@.+\..+/i
  validates :phone, presence: true, uniqueness: true
  validates :phone_normalized, presence: true, uniqueness: true

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

  private

  def set_access_token
    self.access_token = loop do
      access_token = ::Hollerback::Random.friendly_token(40)
      break access_token unless User.find_by_access_token(access_token)
    end
  end

end
