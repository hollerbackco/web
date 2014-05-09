class AddNotifiedToInvites < ActiveRecord::Migration
  def change
    change_table :invites do |t|
      t.boolean :notified, :default => false
    end
  end
end
