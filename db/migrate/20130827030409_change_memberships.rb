class ChangeMemberships < ActiveRecord::Migration
  def up
    change_table :memberships do |t|
      t.string :name
      t.string :thumb_url
    end
    update_memberships
  end

  def down
    remove_column :memberships, :name
    remove_column :memberships, :thumb_url
  end

  def update_memberships
    Membership.all.each do |m|
      next if m.messages.empty?
      next if message = m.messages.first and message.thumb_url.blank?

      p m.name
      m.thumb_url = message.thumb_url
      m.last_message_at = message.sent_at
      m.save
    end
  end
end
