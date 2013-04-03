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

  def self.find_by_phone_numbers(user, invites)
    #todo clean this sql up
    parsed_numbers = Hollerback::ConversationInviter.parse(user,invites)
    parsed_numbers = parsed_numbers + [user.phone_normalized]
    query = Conversation
      .joins("LEFT OUTER JOIN invites ON conversations.id = invites.conversation_id")
      .joins("LEFT OUTER JOIN memberships ON memberships.conversation_id = conversations.id")
      .joins("LEFT OUTER JOIN users ON users.id = memberships.user_id")
      .group("conversations.id")
      .where("users.phone_normalized" => parsed_numbers)
      .where("invites.phone" => parsed_numbers)
      .having("(count(invites.id) + count(users.id)) = ?", parsed_numbers.count).first
  end
end
