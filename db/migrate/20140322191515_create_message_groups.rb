class CreateMessageGroups < ActiveRecord::Migration
  def up
    drop_table :message_groups

    create_table :message_groups do |t|
      t.integer     :membership_id
      t.string      :group_type
      t.hstore      :group_info
      t.timestamps
    end

    add_index :message_groups, :membership_id
    add_index :message_groups, :group_info
  end

  def down
  end
end
