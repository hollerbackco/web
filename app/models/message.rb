class Message < ActiveRecord::Base
  belongs_to :membership

  serialize :content, ActiveRecord::Coders::Hstore

  attr_accessor :display

  scope :seen, where("seen_at is not null")
  scope :unseen, where(:seen_at => nil)
  scope :unseen_within_memberships, lambda {|ids| where("messages.seen_at is null AND messages.membership_id IN (?)", ids)}
  scope :received, where("is_sender IS NOT TRUE")
  scope :sent, where("is_sender IS TRUE")
  scope :updated_since, lambda { |updated_at| where("messages.updated_at > ? ", updated_at) }
  scope :updated_since_within_memberships, lambda { |updated_at, ids| where("messages.updated_at > ? AND messages.membership_id IN (?)", updated_at, ids) }
  scope :before_last_message_at, lambda { |before_message_time, ids| where("messages.seen_at is null AND messages.updated_at < ? AND messages.membership_id IN (?)", before_message_time, ids) }
  scope :before, lambda { |time| where("messages.sent_at < ?", time) }
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
    self.all_by_guid(str).first
  end

  def self.all_by_guid(str)
    where("content -> 'guid'='#{str}'")
  end

  def self.sync_objects(opts={})
    get_objects(opts).map(&:to_sync)
  end

  def self.get_objects(opts={})
    raise ArgumentError if opts[:user].blank?
    options = {
        :since => nil,
        :before => nil,
        :membership_ids => []
    }.merge(opts)

    collection = options[:user].messages.watchable

    collection = if options[:since]
                   collection.updated_since_within_memberships(options[:since], options[:membership_ids])
                 elsif options[:before]
                   collection.before_last_message_at(options[:before], options[:membership_ids])
                 else               #how much of an improvement will one query be? Quite a bit!
                   collection.unseen_within_memberships(options[:membership_ids])
                 end
    begin
      Message.set_message_display_info(collection)
    rescue Exception => e
      logger.error e
    end

    collection
  end


  def user
    {
        name: sender_name,
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

  def gif_url
    content["gif_url"]
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

  def seen?
    seen_at.present?
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
        sync: as_json
    }
  end

  def as_json(opts={})
    options = {}
    options = options.merge(:methods => [:guid, :url, :thumb_url, :gif_url, :conversation_id, :user, :is_deleted, :subtitle, :display])
    options = options.merge(:only => [:created_at, :sender_name, :sent_at, :needs_reply])
    options = options.merge(opts)
    super(options).merge({isRead: !unseen?, id: guid})
  end

  def self.set_message_display_info(messages)

    video_rules = HollerbackApp::ClientDisplayManager.get_rules_by_name('video_cell_display_rules')

    #user display info
    user_display = video_rules['user']

    #other display info
    other_display = video_rules['others']

    #for each message add it's display info
    messages.each do |message|
      message.is_sender? ? message.display = user_display : message.display = other_display
    end
  end
end
