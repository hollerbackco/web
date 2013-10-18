class Message < ActiveRecord::Base
  belongs_to :membership
  belongs_to :video, :foreign_key => "video_guid",
    :class_name => "Video",
    :primary_key => "guid"

  serialize :content, ActiveRecord::Coders::Hstore

  scope :seen, where("seen_at is not null")
  scope :unseen, where(:seen_at => nil)
  scope :received, where("is_sender IS NOT TRUE")
  scope :sent, where("is_sender IS TRUE")
  scope :updated_since, lambda {|updated_at| where("messages.updated_at > ?", updated_at)}
  scope :before, lambda {|time| where("messages.updated_at < ?", time)}

  after_create do |record|
    m = record.membership
    m.last_message_at = record.sent_at
    if !record.sender? or m.most_recent_thumb_url.blank?
      m.most_recent_thumb_url = record.thumb_url
    end
    m.save
  end

  def sender?
    is_sender
  end

  def self.sync_objects(opts={})
    raise ArgumentError if opts[:user].blank?
    options = {
      :since => nil
    }.merge(opts)

    collection = options[:user].messages

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

  def url
    content["url"]
  end

  def thumb_url
    content["thumb_url"]
  end

  def subtitle
    content["subtitle"]
  end

  def filename
    video.filename
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
      membership.touch
      self.deleted_at = Time.now
      self.save!
    end
  end

  def deleted?
    deleted_at.present?
  end
  alias_method :is_deleted, :deleted?

  def guid
    video_guid
  end

  def conversation_id
    membership_id
  end

  def to_sync
    {
      type: "message",
      sync: as_json({
        :methods => [:guid, :url, :thumb_url, :conversation_id, :user, :is_deleted]
      })
    }
  end

  def as_json(opts={})
    options = {}
    options = options.merge(:methods => [:url, :thumb_url, :conversation_id, :user, :filename, :is_deleted])
    options = options.merge(:only => [:created_at, :sender_name, :sent_at, :needs_reply])
    options = options.merge(opts)
    super(options).merge({isRead: !unseen?, id: guid})
  end
end
