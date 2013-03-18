class Conversation < ActiveRecord::Base
  attr_accessible :creator, :invites

  has_many :videos, order: "videos.created_at DESC"
  has_many :memberships
  has_many :members, through: :memberships, source: :user, class_name: "User"
  has_many :invites

  belongs_to :creator, class_name: "User"

end
