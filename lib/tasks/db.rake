namespace :db do
  desc 'Create the database defined in config/database.yml for the current APP_ENV'
  task :create do
    Hollerback::Tasks::DatabaseTasks.create_database
  end

  desc 'Drops the database for the current APP_ENV'
  task :drop do
    begin
      Hollerback::Tasks::DatabaseTasks.drop_database
    rescue Exception => e
      puts "Couldn't drop database : #{e.inspect}"
    end
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => [:environment, :load_config] do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback(ActiveRecord::Migrator.migrations_paths, step)
    db_namespace['_dump'].invoke
  end

  # desc 'Pushes the schema to the next version (specify steps w/ STEP=n).'
  task :forward => [:environment, :load_config] do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.forward(ActiveRecord::Migrator.migrations_paths, step)
    db_namespace['_dump'].invoke
  end
end

module Hollerback
  module Tasks
    module DatabaseTasks
      extend self

      def create_database
        establish_master_connection
        connection.create_database config['database'],
          config.merge('encoding' => encoding)

        establish_connection configuration
      end

      def drop_database
        establish_master_connection
        connection.drop_database config[:database]
      end

      private

      def config
        @config ||= ActiveRecord::Base.connection_config
      end

      def connection
        ActiveRecord::Base.connection
      end

      def establish_master_connection
        ActiveRecord::Base.establish_connection config.merge(
          'database'           => 'postgres',
          'schema_search_path' => 'public'
        )
      end
    end
  end
end
