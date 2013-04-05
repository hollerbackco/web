class Conversation < ActiveRecord::Base
  attr_accessible :creator, :invites, :name

  has_many :videos, order: "videos.created_at DESC", :dependent => :destroy
  has_many :memberships
  has_many :members, through: :memberships, source: :user, class_name: "User"
  has_many :invites

  belongs_to :creator, class_name: "User"

  def name
    member_names = members.map {|member| member.name }
    auto_name = member_names.join(", ")
    self[:name] || auto_name
  end

  def involved_phones
    members.map(&:phone_normalized) + invites.map(&:phone)
  end

  def self.find_by_phone_numbers(user, invites)
    #todo do this with sql
    parsed_numbers = Hollerback::ConversationInviter.parse(user,invites)
    parsed_numbers = parsed_numbers + [user.phone_normalized]

    user.member_of.keep_if do |conversation|
      numbers = conversation.involved_phones
      parsed_numbers.count == numbers.count && (parsed_numbers - conversation.involved_phones).empty?
    end.first
  end
end
