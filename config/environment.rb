require 'rubygems'
require 'bundler'
Bundler.require

require 'will_paginate'
require 'will_paginate/active_record'

# setup config vars
env_file = File.join('config', 'local_env.yml')
YAML.load(File.open(env_file)).each do |key, value|
  ENV[key.to_s] ||= value
end if File.exists?(env_file)

module HollerbackApp
  class BaseApp < ::Sinatra::Base
    register ::Sinatra::ActiveRecordExtension

    # Setup db
    set :database, ENV["DATABASE_URL"]
    set :redis, ENV["REDISTOGO_URL"]
    if ENV["MEMCACHIER_SERVERS"]
      set :cache, Dalli::Client.new( ENV['MEMCACHIER_SERVERS'],
                                     :username => ENV['MEMCACHIER_USERNAME'],
                                     :password => ENV['MEMCACHIER_PASSWORD'],
                                     :expires_in => 1.day)
    else
      set :cache, Dalli::Client.new
    end
  end
end

# Setup lib
%w[lib config/initializers].each do |dir|
  Dir.glob("./#{dir}/**/*.rb").each do |relative_path|
    require relative_path
  end
end

# Setup app
require File.expand_path('./app/app')
