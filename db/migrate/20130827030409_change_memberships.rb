class ChangeMemberships < ActiveRecord::Migration
  def up
    change_table :memberships do |t|
      t.string :name
      t.string :most_recent_thumb_url
    end
    update_memberships
  end

  def down
    remove_column :memberships, :name
    remove_column :memberships, :most_recent_thumb_url
  end

  def update_memberships
    Membership.all.each do |m|
      next if m.messages.empty?
      message = m.messages.first
      next if message.thumb_url.blank?

      p m.name
      m.most_recent_thumb_url = message.thumb_url
      m.last_message_at = message.sent_at
      p m.most_recent_thumb_url
      m.save!
    end
  end
end
