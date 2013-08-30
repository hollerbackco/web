class Message < ActiveRecord::Base
  belongs_to :membership
  serialize :content, ActiveRecord::Coders::Hstore

  scope :unseen, where(:seen_at => nil)
  scope :updated_since, lambda {|updated_at| where("messages.updated_at > ?", updated_at)}

  after_create do |record|
    record.membership.last_message_at = record.sent_at
    record.membership.most_recent_thumb_url = record.thumb_url
    record.membership.save
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
      collection.limit(100)
    end

    collection.map(&:to_sync)
  end

  def conversation_id
    membership_id
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

  def to_sync
    {
      type: "message",
      sync: as_json
    }
  end

  def as_json(options={})
    options = options.merge(:methods => [:url, :thumb_url, :conversation_id, :user])
    options = options.merge(:except => [:membership_id])
    super(options).merge({isRead: !unseen?})
  end
end
