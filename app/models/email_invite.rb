class EmailInvite < ActiveRecord::Base
  belongs_to :inviter, class_name: "User"

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(?:\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX}, uniqueness: {case_sensitive: false}

  before_save {self.email = email.downcase}
end