class CreateMessages < ActiveRecord::Migration
  class Message < ActiveRecord::Base
    belongs_to :membership
    belongs_to :content
  end

  def up
    create_table :messages do |t|
      t.integer :membership_id
      t.boolean :is_sender
      t.string :sender_name
      t.string :content_guid
      t.hstore :content
      t.datetime :sent_at
      t.datetime :seen_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :messages, :membership_id
  end

  def down
    drop_table :messages
  end

  private

  def create_messages
    ActiveRecord::Base.record_timestamps = false
    Video.all.each do |video|
      next if video.converation.blank?
      next if video.filename.blank?
      next if video.user.blank?

      conversation.members.each do |member|
        conversation = video.conversation
        sender = video.user
        membership = Membership.first(:conversation_id => conversation.id, :user_id => member.id)

        Message.new(
          membership_id: membership.id,
          is_sender: (sender == member),
          sender_name: sender.also_known_as(for: member),
          content_guid: video.id,
          content: {
            url: video.url,
            thumb_url: video.thumb_url
          },
          seen_at: Time.now,
          sent_at: video.created_at,
          created_at: video.created_at,
          updated_at: Time.now,
          deleted_at: nil
        )
      end
    end
    ActiveRecord::Base.record_timestamps = true
  end
end
