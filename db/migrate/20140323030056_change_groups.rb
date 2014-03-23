class ChangeGroups < ActiveRecord::Migration
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
          if(message_group != nil)
            if(message.sent_at -  message_group.group_info[:start_time] <= 60 && message.sender_id == message_group.group_info[:sender_id])
              message.group_id = message_group.id
              message.save
              next
            end
            message_group = nil
          end
          next_message = messages[index + 1]

          if(next_message != nil) #there's potential for a group to be created
            if(next_message.sent_at - message.sent_at <= 60 && message.sender_id == next_message.sender_id)
              #create a group because the messages are only less than a minute apart
              group_info = { :start_time => message.sent_at, :sender_id => message.sender_id}
              message_group = MessageGroup.create(:group_info => group_info)

              group_id = message_group.id
              message.group_id = group_id
              message.save

              #create a group
              membership.message_groups << message_group
            end
          end

        end

      end

    end
  end
end
