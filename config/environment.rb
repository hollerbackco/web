require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'sinatra' unless defined? Sinatra
require "sinatra/activerecord"

set :database, ENV["database_url"] || "postgres:///hollerback_dev"

Dir.open("./app/models").each do |file|
  next if file =~ /^\./
  require File.expand_path("./app/models/#{file}")
end

Dir.open("./config/initializers").each do |file|
  next if file =~ /^\./
  require File.expand_path("./config/initializers/#{file}")
end

module HollerbackApp
  class BaseApp < ::Sinatra::Base
    register ::Sinatra::ActiveRecordExtension

    configure :development do
      enable :logging, :dump_errors, :raise_errors
    end
  end
end
