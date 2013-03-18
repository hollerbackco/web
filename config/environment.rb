require 'rubygems'
require 'bundler'
Bundler.require

# Set up gems listed in the Gemfile.
#ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
#require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

# Setup lib
%w[lib config/initializers].each do |dir|
  Dir.glob("./#{dir}/**/*.rb").each do |relative_path|
    require relative_path
  end
end

# Setup db
set :database, ENV["DATABASE_URL"] || "postgres:///hollerback_dev"

# Setup app
require File.expand_path('./app/app')
