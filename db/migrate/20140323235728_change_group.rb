class ChangeGroup < ActiveRecord::Migration
  def change
    update_db
  end

  def update_db
    #get each user
    users = User.all

    #for each user get the memberships
    users.each do |user|
      memberships = user.memberships

      memberships.each do |membership|

        messages = membership.messages.order(:sent_at)

        message_group = nil #a message group

        messages.each_with_index do |message, index|

          #case when a group has already been created
          unless message_group.nil?

            if( !message.sent_at.blank? &&  (message.sent_at -  Time.parse(message_group.group_info["end_time"])) <= 60 && (message.sender_id.to_s == message_group.group_info["sender_id"]))
              message_group.messages << message
              message_group.group_info["end_time"] = message.sent_at
              message.save
              message_group.save
              next
            end
            message_group = nil
          end

          next_message = messages[index + 1]
          if(!next_message.nil? && !next_message.sent_at.nil?) #there's potential for a group to be created
            next if next_message.sent_at.nil? || message.sent_at.nil?

            if(next_message.sent_at - message.sent_at <= 60 && message.sender_id == next_message.sender_id)
              #create a group because the messages are only less than a minute apart
              group_info = { "start_time" => message.sent_at, "end_time" => message.sent_at,"sender_id" => message.sender_id }
              message_group = MessageGroup.create(:group_info => group_info)

              message_group.messages << message
              message.save

              p "created group with id"
              #create a group
              membership.message_groups << message_group
              message_group.save
            end
          end
        end    #messages.do
      end      #membership.do
    end        #users.do
  end          #update_db
end            #class