class Message < ActiveRecord::Base
  belongs_to :membership

  serialize :content, ActiveRecord::Coders::Hstore

  scope :seen, where("seen_at is not null")
  scope :unseen, where(:seen_at => nil)
  scope :received, where("is_sender IS NOT TRUE")
  scope :sent, where("is_sender IS TRUE")
  scope :updated_since, lambda {|updated_at| where("messages.updated_at > ?", updated_at)}
  scope :before, lambda {|time| where("messages.updated_at < ?", time)}
  scope :watchable, where("content ? 'guid'")

  after_create do |record|
    m = record.membership
    m.deleted_at = nil
    m.last_message_at = record.sent_at || record.created_at
    if !record.sender? or m.most_recent_thumb_url.blank?
      if !record.ttyl?
        m.most_recent_thumb_url = record.thumb_url
      end
    end
    m.most_recent_subtitle = record.subtitle
    m.save
  end

  def sender?
    is_sender
  end

  def self.find_by_guid(str)
    where("content -> 'guid'='#{str}'").first
  end

  def self.sync_objects(opts={})
    raise ArgumentError if opts[:user].blank?
    options = {
      :since => nil
    }.merge(opts)

    collection = options[:user].messages.watchable

    collection = if options[:since]
      collection.updated_since(options[:since])
    else
      collection.unseen
    end

    collection.map(&:to_sync)
  end

  def user
    {
      name: sender_name
    }
  end

  def ttyl?
    !content.key? "guid"
  end

  def url
    content["url"]
  end

  def thumb_url
    content["thumb_url"]
  end

  def subtitle
    (content["subtitle"] || "").force_encoding("UTF-8")
  end

  def guid
    content["guid"]
  end

  def video_guid=(str)
    content["guid"] = str
  end

  def filename
    Video.find_by_guid(content["guid"]).filename
  end

  def unseen?
    seen_at.blank?
  end

  def seen!
    self.class.transaction do
      membership.touch
      self.seen_at = Time.now
      self.save!
    end
  end

  def delete!
    self.class.transaction do
      self.deleted_at = Time.now
      self.save!
    end
  end

  def deleted?
    deleted_at.present?
  end
  alias_method :is_deleted, :deleted?

  def conversation_id
    membership_id
  end

  def to_sync
    {
      type: "message",
      sync: as_json({
        :methods => [:guid, :url, :thumb_url, :conversation_id, :user, :is_deleted, :subtitle]
      })
    }
  end

  def as_json(opts={})
    options = {}
    options = options.merge(:methods => [:url, :thumb_url, :conversation_id, :user, :filename, :is_deleted, :subtitle])
    options = options.merge(:only => [:created_at, :sender_name, :sent_at, :needs_reply])
    options = options.merge(opts)
    super(options).merge({isRead: !unseen?, id: guid})
  end
end
