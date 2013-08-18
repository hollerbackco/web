class Conversation < ActiveRecord::Base
  attr_accessible :creator, :name

  has_many :videos, order: "videos.created_at DESC", :dependent => :destroy
  has_many :memberships
  has_many :members, through: :memberships, source: :user, class_name: "User"
  has_many :invites, conditions: {accepted: false}

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

  def unread_videos_for(user)
    videos_for(user).unread_by(user)
  end

  def clear_unread_for(user)
    unread_videos = videos_for(user).unread_by(user)
    unread_videos.each do |video|
      video.mark_as_read! for: user
    end

    key = "user/#{user.id}/conversations/#{self.id}-#{self.updated_at}"
    HollerbackApp::BaseApp.settings.cache.delete key

    user.memcache_key_touch
    user.devices.ios.each do |device|
      APNS.send_notification(device.token, badge: user.unread_videos.count)
    end
  end

  # all conversations with a name that is set.
  def group?
    members.count > 2 or self[:name].present?
  end
  alias_method :is_group, :group?

  def member_names(discluded_user=nil)
    people = members
    name = if discluded_user.present?
      people = members - [discluded_user]
      people.map {|user| user.also_known_as(:for => discluded_user) }
    else
      people.map {|user| user.username }
    end

    people.any? ? name.join(", ") : nil
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
