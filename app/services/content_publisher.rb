class ContentPublisher
  attr_accessor :membership, :conversation, :messages

  def initialize(membership)
    @membership = membership
    @conversation = membership.conversation
  end

  def publish(content)
    self.messages = conversation.memberships.map do |m|
      send_to(m, content)
    end
    notify_recipients(messages)
    publish_analytics(content)
  end

  def send_to(membership, content)
    sender = content.user
    member = membership.user

    membership.touch

    if sender == member
      is_sender = true
      seen_at = Time.now
    else
      is_sender = false
    end
    obj = {
      membership_id: membership.id,
      is_sender: is_sender,
      sender_name: sender.also_known_as(for: member),
      content_guid: content.id,
      content: content.content_hash,
      seen_at: seen_at,
      sent_at: content.created_at
    }
    Message.create(obj)
  end

  def sender_message
    messages.select {|m| m.is_sender }.first
  end

  private

  def notify_recipients(messages)
    Hollerback::NotifyRecipients.new(messages).run
  end

  def publish_analytics(content)
    Keen.publish("video:create", {
      id: content.id,
      receivers_count: (content.conversation.members.count - 1),
      conversation: {
        id: content.conversation.id,
        videos_count: content.conversation.videos.count
      },
      user: {id: content.user.id, username: content.user.username}
    })
  end
end
