class PgUuidExt < ActiveRecord::Migration
  def self.up
    execute 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
  end

  def self.down
    execute 'DROP EXTENSION "uuid-ossp"'
  end
end
