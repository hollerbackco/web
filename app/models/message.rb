class Message < ActiveRecord::Base
  belongs_to :membership
  serialize :content, ActiveRecord::Coders::Hstore

  scope :unseen, where(:seen_at => nil)
  scope :updated_since, lambda {|updated_at| where("messages.updated_at > ?", updated_at)}

  after_create {|record| membership.last_message_at = record.sent_at; membership.save }

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

  def url
    content["url"]
  end

  def thumb_url
    content["thumb_url"]
  end

  def unseen?
    membership.update_unseen!
    seen_at.blank?
  end

  def seen!
    seen_at = Time.now
    save!
  end

  def delete!
    deleted_at = Time.now
    save!
  end

  def to_sync
    {
      type: "message",
      obj: as_json
    }
  end

  def as_json(options={})
    options = options.merge(:methods => [:url, :thumb_url, :conversation_id])
    options = options.merge(:except => [:membership_id])
    super(options).merge({isRead: !unseen?})
  end
end
