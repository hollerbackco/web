class ContentPublisher
  include Sinatra::CoreHelpers

  attr_accessor :membership, :conversation, :messages, :is_first_message, :sender

  def initialize(membership)
    @membership = membership
    @sender = @membership.user
    @conversation = membership.conversation
    @is_first_message = (@conversation.videos.count == 1)
  end

  def publish(content, opts={})
    options = {notify: true, analytics: true}.merge(opts)
    self.messages = conversation.memberships.map do |m|
      send_to(m, content)
    end.compact
    notify_recipients(messages) if options[:notify]
    publish_analytics(content) if options[:analytics]
    sms_invite(conversation, content) if is_first_message
  end

  def send_to(membership, content)
    member = membership.user
    # check to see that the user actually exists
    return nil if member.blank?

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

  def sms_invite(phones, content)
    conversation.invites.map(&:phone).each do |phone|
      msg = "#{sender.username} sent you a message on hollerback. #{video_share_url content}"
      #TODO: send a text message to non users
      Hollerback::SMS.send_message phone, msg
    end
  end
end
