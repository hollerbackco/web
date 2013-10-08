class ContentPublisher
  include Sinatra::CoreHelpers

  attr_accessor :membership, :conversation, :messages, :is_first_message, :sender, :is_reply

  def initialize(membership, is_reply=false)
    @membership = membership
    @sender = @membership.user
    @conversation = membership.conversation

    #TODO currently set to always be true, but uncomment to only send one invite
    #@is_first_message = (@conversation.videos.count == 1)
    @is_first_message = true

    @is_reply = is_reply
  end

  def publish(content, opts={})
    options = {notify: true, analytics: true}.merge(opts)

    memberships = options.key?(:to) ? [options[:to]] : conversation.memberships

    self.messages = memberships.map do |m|
      send_to(m, content)
    end.compact

    notify_recipients(messages) if options[:notify]
    publish_analytics(content) if options[:analytics] and is_first_message
    sms_invite(conversation, content) if is_first_message
    say_level(sender)
  end

  def send_to(membership, content)
    member = membership.user

    # check to see that the user actually exists
    return nil if member.blank?

    # dont send message if the user has been muted
    return nil if member.muted?(sender)

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
      video_guid: content.guid,
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
    data = {
      content_id: content.id,
      is_reply: is_reply,
      receivers_count: (conversation.members.count - 1),
      conversation: {
        id: conversation.id,
        videos_count: conversation.videos.count
      }
    }
    MetricsPublisher.publish(content.user, "video:create", data)
  end

  def sms_invite(conversation, content)
    phones = conversation.invites.pending.map(&:phone)
    phones.each do |phone|
      url = create_video_share_url(content, phone)
      msg = "#{sender.username} sent you a message on hollerback. #{url}"
      Hollerback::SMS.send_message phone, msg, content.thumb_url
    end
  end

  def say_level(user)
    begin
      levels = [5,10,25,50,100,250,500,1000]
      if level = levels.index(user.videos.count)
        level = level + 1
        Hollerback::BMO.say("#{user.username} has leveled up: #{level}")
      end
    rescue
    end
  end
end
