class Invite < ActiveRecord::Base
  attr_accessible :phone, :inviter, :conversation, :accepted

  belongs_to :inviter, class_name: "User"
  belongs_to :conversation

  scope :pending, where(accepted: false)
  scope :pending_for_user, lambda {|user| pending.where(phone: user.phone_normalized)}

  def accept!
    update_attribute! :accepted, true
  end
end
