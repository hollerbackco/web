# a membership is a subscription to a conversation
# memberships is a subsciption to a topic
# memberships can also publish to that topic
class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :conversation
  has_many :messages
  has_many :unseen_messages, foreign_key: "membership_id", class_name: "Message", conditions: {seen_at: nil}

  delegate :invites, :members, to: :conversation

  default_scope { order("last_message_at DESC") }

  before_create { |record| record.last_message_at = Time.now }

  scope :updated_since, lambda {|updated_at| where("memberships.updated_at > ?", updated_at)}

  def self.sync_objects(opts={})
    raise ArgumentError if opts[:user].blank? and !opts[:user].is_a? User
    options =  {
      :since => nil,
    }.merge(opts)

    collection = options[:user].memberships

    if options[:since]
      collection = collection.updated_since(options[:since])
    end

    collection.map(&:to_sync)
  end

  def recipient_memberships
    conversation.memberships - [self]
  end

  def others
    conversation.members - [user]
  end

  # todo: cache this
  def name
    update_conversation_name if self[:name].blank?
    self[:name]
  end

  def update_conversation_name
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
      others.map {|other| other.also_known_as(:for => user)}.join(", ").truncate(100).strip
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

  def update_unseen!
    touch
  end

  def as_json(options={})
    options = options.merge(methods: [:name, :unread_count, :is_group])
    super(options)
  end

  def to_sync
    {
      type: "conversation",
      sync: as_json
    }
  end
end
