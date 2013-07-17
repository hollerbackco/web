class Invite < ActiveRecord::Base
  attr_accessible :phone, :inviter, :conversation, :accepted

  belongs_to :inviter, class_name: "User"
  belongs_to :conversation

  scope :pending, where(accepted: false)
  scope :pending_for_user, lambda {|user| pending.where(phone: user.phone_normalized)}

  validates :phone, presence: true

  def accepted?
    accepted
  end

  def accept!(user)
    self.transaction do 
      conversation.members << user
      self.accepted = true
      save!
    end
  end
end
