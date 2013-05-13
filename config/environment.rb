require 'rubygems'
require 'bundler'
Bundler.require

# setup config vars
env_file = File.join('config', 'local_env.yml')
YAML.load(File.open(env_file)).each do |key, value|
  ENV[key.to_s] ||= value
end if File.exists?(env_file)

# Setup db
set :database, ENV["DATABASE_URL"]
set :redis, ENV["REDISTOGO_URL"]

# Setup lib
%w[lib config/initializers].each do |dir|
  Dir.glob("./#{dir}/**/*.rb").each do |relative_path|
    require relative_path
  end
end

# Setup app
require File.expand_path('./app/app')
