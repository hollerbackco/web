class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts do |t|
      t.id :user_id
      t.string :hashed_phone
      t.string :name
    end
    add_index :contacts, :hashed_phone
    add_index :contacts, [:user_id, :hashed_phone]
  end
end
