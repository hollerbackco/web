class CreateGroups < ActiveRecord::Migration
  def change
    create_groups
  end

  def create_groups
    #for each user get the memberships
    memberships = Membership.all

    memberships.each do |membership|

      messages = membership.messages.order(:sent_at)

      message_group = nil #a message group

      messages.each do |message|

        next if message.sent_at.blank?
        #case when a group has already been created
        if (!message_group.nil? && (message.sent_at - Time.parse(message_group.group_info["end_time"])) <= 60 && (message.sender_id.to_s == message_group.group_info["sender_id"]))
          message_group.group_info["end_time"] = message.sent_at
          message_group.messages << message
          message.save
          message_group.save
          next
        else #create a new message group if we can't add it to the previous one
          group_info = {"start_time" => message.sent_at, "end_time" => message.sent_at, "sender_id" => message.sender_id}
          message_group = MessageGroup.create(:group_info => group_info)
          message_group.messages << message
          membership.message_groups << message_group
          message_group.save
          message.save
        end
      end #messages.do
    end #membership.do
  end
end #class