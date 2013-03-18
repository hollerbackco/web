class Waitlister < ActiveRecord::Base
  attr_accessible :email

  validates :email, presence: true, uniqueness: {:message => 'thanks, you\'re on the list'}
  validates_format_of :email, with: /.+@.+\..+/i
end
