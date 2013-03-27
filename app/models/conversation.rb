class Conversation < ActiveRecord::Base
  attr_accessible :creator, :invites, :name

  has_many :videos, order: "videos.created_at DESC"
  has_many :memberships
  has_many :members, through: :memberships, source: :user, class_name: "User"
  has_many :invites

  belongs_to :creator, class_name: "User"

  def name
    member_names = members.map {|member| member.name }
    auto_name = member_names.join(", ")
    self[:name] || auto_name
  end
end
