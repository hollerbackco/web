# a membership is a subscription to a conversation
# memberships is a subsciption to a topic
# memberships can also publish to that topic
class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :conversation

  has_many :messages

  delegate :invites, :members, to: :conversation

  before_create { |record| record.last_message_at = Time.now }

  def recipient_memberships
    conversations.memberships - [self]
  end

  def others
    conversation.members - [user]
  end

  # todo: cache this
  def name
    update_conversation if self[:name].blank?
    self[:name]
  end

  def update_conversation
    class << self
      def record_timestamps; false; end
    end

    self.name = conversation.name || auto_generated_name
    save!

    class << self
      def record_timestamps; super; end
    end
  end

  def auto_generated_name
    if others.blank?
      "#{conversation.invites.count} Invited"
    else
      others.map {|other| other.also_known_as(:for => user)}.join(", ").truncate(100).trim
    end
  end

  def unseen?
    messages.unseen.present?
  end

  def view_all
    messages.unseen.each {|m| m.seen! }
  end

  def group?
    conversation.group?
  end
  alias_method :is_group, :group?

  def unseen_count
    messages.unseen.present?
  end
  alias_method :unread_count, :unseen_count

  def as_json(options={})
    options = options.merge(methods: [:name, :unread_count, :is_group])
    super(options)
  end
end
