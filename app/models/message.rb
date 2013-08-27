class Message < ActiveRecord::Base
  belongs_to :membership
  serialize :content, ActiveRecord::Coders::Hstore

  scope :unseen, where(:seen_at => nil)

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

  def as_json(options={})
    options = options.merge(:methods => [:url, :thumb_url, :conversation_id])
    options = options.merge(:except => [:membership_id])
    super(options).merge({isRead: !unseen?})
  end
end
