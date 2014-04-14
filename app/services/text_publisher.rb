#this class will publish the text message to all memberships
class TextPublisher
  include Sidekiq::Worker

  def perform(sender_id, conversation_id, text, guid, created_at)
    @sender = User.find(sender_id)
    @conversation = Conversation.find(conversation_id)
    @text = text
    @guid = guid
    @created_at = created_at

    publish
  end

  def publish

    if Message.where("content -> 'guid' = ?", @guid).any?
      HollerbackApp::BaseApp::logger.error "message with guid: #{@guid} already exists"
      return
    end

    #for each membership create a new message
    messages = @conversation.memberships.map do |membership|
      logger.info "membership username: #{membership.user.name}"
      is_sender = (membership.user == @sender) ? true : false
      needs_reply = (membership.user == @sender) ? false : true
      seen_at = Time.now if (membership.user == @sender)

      obj = {
          membership_id: membership.id,
          is_sender: is_sender,
          sender_id: @sender.id,
          sender_name: @sender.also_known_as(for: @sender),
          content: {:text => @text, :guid => @guid},
          seen_at: seen_at,
          sent_at: @created_at,
          message_type: Message::Type::TEXT,
          needs_reply: needs_reply
      }
      Message.create(obj)
    end

    Hollerback::NotifyRecipients.new(messages).run

  end

end