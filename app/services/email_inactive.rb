class EmailInactive
  def self.run(dryrun=false)
    User.find_each do |user|
      emailer = self.new(user: user, dryrun: dryrun)
      if emailer.remind
        counter = counter + 1
      end
    end
    p "#{counter} users emailed"
  end

  attr_accessor :dryrun, :user
  def initialize(opts={})
    @dryrun = opts[:dryrun] || false
    @user = opts[:user]
  end


  def remind
    if remindable?
      from_username = from_membership.name
      message_count = from_membership.messages.watchable.unseen.count
      send_email(from_username, message_count)
      #create_record
    end
  end

  def send_email(from_username, message_count)
    puts "sent email to #{user.email}"
    puts from_username
    puts message_count
    sender = user
    Mail.deliver do
      to sender.email
      from 'no-reply@hollerback.co'
      subject "#{from_username} sent you a message on Hollerback"

      html_part do
        body "<p>Hey there,</p><p>You have #{message_count} new message#{message_count > 1 ? "s" : ""} on Hollerback from #{from_username}.</p><p><a href='hollerback://'>View message</a></p>"
      end
    end
  end

  def from_membership
    message = user.messages.received.unseen.first
    membership = message.membership
  end

  def remindable?
    has_unseen? and inactive_for_more_than_a_week? and !email_reminded?
  end

  def has_unseen?
    user.unseen_messages.any?
  end

  def inactive_for_more_than_a_week?
    return true if user.last_active_at.blank?
    user.last_active_at < (Time.now - 1.week)
  end

  def email_reminded?
    data.key? "sent_at"
  end

  private

  def create_record
    key = "user:#{user.id}:email_remind"
    new_data = ::MultiJson.encode({sent_at: Time.now})
    REDIS.set(key, new_data)
  end

  def data
    data = REDIS.get("user:#{user.id}:email_remind")
    if data
      ::MultiJson.decode(data)
    else
      {}
    end
  end
end
