class Waitlister < ActiveRecord::Base
  attr_accessible :email

  validates :email, presence: true, uniqueness: true
  validates_format_of :email, with: /.+@.+\..+/i
end
