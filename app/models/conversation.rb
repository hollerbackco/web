class Conversation < ActiveRecord::Base
  attr_accessible :creator, :name

  has_many :videos, order: "videos.created_at DESC", :dependent => :destroy
  has_many :memberships
  has_many :members, through: :memberships, source: :user, class_name: "User"
  has_many :invites

  belongs_to :creator, class_name: "User"

  default_scope order("updated_at DESC")

  # all videos sent by user or all videos that are complete
  def videos_for(user)
    if user
      t = Video.arel_table
      videos.where(
        t[:user_id].eq(user.id).
        or(t[:in_progress].eq(false))
      )
    else
      videos
    end
  end

  # all conversations with a name that is set.
  def group?
    members.count > 2 or self[:name].present?
  end
  alias_method :is_group, :group?

  def member_names(discluded_user=nil)
    people = members
    if discluded_user.present?
      people = members - [discluded_user]
    end
    people.any? ? people.map {|user| user.username }.join(", ") : nil
  end

  def name(discluded_user=nil)
    self[:name] || member_names(discluded_user) || "(#{invites.count}) Invited"
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
