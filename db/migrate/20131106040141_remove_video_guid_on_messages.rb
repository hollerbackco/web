class RemoveVideoGuidOnMessages < ActiveRecord::Migration
  def up
    set_video_guids
    remove_column :messages, :video_guid
  end

  def down
    # messages
    execute "ALTER TABLE messages ADD COLUMN video_guid uuid;"
    execute "ALTER TABLE messages ALTER COLUMN video_guid SET NOT NULL;"
    add_index :messages, [:membership_id, :video_guid], :unique => true
  end

  private

  def set_video_guids
    Message.where("content is not null").find_each do |message|
      message.content["guid"] = message.video_guid
      message.save
    end
  end
end
