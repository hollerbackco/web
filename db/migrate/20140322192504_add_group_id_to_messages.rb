class AddGroupIdToMessages < ActiveRecord::Migration
  def change
    change_table :messages do |t|
      t.integer :message_group_id
    end
  end

end
