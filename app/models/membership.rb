# a membership is a subscription to a conversation
# memberships is a subsciption to a topic
# memberships can also publish to that topic
class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :conversation
  has_many :messages

  delegate :invites, to: :conversation

  default_scope { order("last_message_at DESC") }

  before_create { |record| record.last_message_at = Time.now }

  scope :updated_since, lambda {|updated_at| where("memberships.updated_at > ?", updated_at)}

  def self.sync_objects(opts={})
    raise ArgumentError if opts[:user].blank? and !opts[:user].is_a? User
    options =  {
      :since => nil,
    }.merge(opts)

    collection = self.where(user_id: options[:user].id)

    if options[:since]
      collection = collection.updated_since(options[:since])
    end

    collection = collection
      .joins("LEFT OUTER JOIN messages ON memberships.id = messages.membership_id AND messages.seen_at is null")
      .group("memberships.id")
      .select('memberships.*, count(messages) as unseen_count')

    collection.map(&:to_sync)
  end

  def recipient_memberships
    conversation.memberships - [self]
  end

  def others
    conversation.members - [user]
  end

  def members
    others.map do |other|
      {
        id: other.id,
        name: other.also_known_as(for: user),
        is_blocked: user.muted?(other)
      }
    end
  end

  # todo: cache this
  def name
    update_conversation_name if self[:name].blank?
    self[:name]
  end

  def update_conversation_name
    self.name = conversation.name || auto_generated_name
    save!
  end

  def auto_generated_name
    names = others.map {|other| other.also_known_as(:for => user)}
    names = names + conversation.invites.map do |invite|
      invite.also_known_as(:for => user)
    end
    name = names.join(", ").truncate(100).strip

    name.blank? ? "no one's here" : name
  end

  def videos
    # TODO cleanup and no longer have this in the json
    messages.limit(10)
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
    self["unseen_count"] || messages.unseen.count
  end
  alias_method :unread_count, :unseen_count

  def update_seen!
    touch
  end

  def is_deleted
    false
  end

  def as_json(opts={})
    options = {}
    options = options.merge(methods: [:name, :unread_count, :is_group, :videos, :members, :is_deleted])
    options = options.merge(except: [:updated_at, :conversation_id])
    options = options.merge(opts)
    obj = super(options)

    # TODO cleanup updated_at [hacky][ios]
    # override updated_at timestamp to allow for correct sorting on older versions of the ios app
    obj.merge({updated_at: last_message_at})
  end

  def to_sync
    {
      type: "conversation",
      sync: as_json({methods: [:name, :unread_count, :is_deleted]})
    }
  end
end
