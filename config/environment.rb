require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'active_record/errors'
require 'active_support/all'
require 'warden'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

# Setup lib
%w[lib config/initializers].each do |dir|
  Dir.glob("./#{dir}/**/*.rb").each do |relative_path|
    require relative_path
  end
end

# require apps
module HollerbackApp
  class BaseApp < ::Sinatra::Base
    helpers ::Sinatra::Warden::Helpers
    register ::Sinatra::ActiveRecordExtension

    configure :development do
      enable :logging, :dump_errors, :raise_errors
    end

    before do
      logger.info "[params] #{params.inspect}"
    end
  end
end

require File.expand_path('./app/app')
require File.expand_path('./app/session')
require File.expand_path('./app/register')


set :database, ENV["DATABASE_URL"] || "postgres:///hollerback_dev"

Dir.open("./app/models").each do |file|
  next if file =~ /^\./
  require File.expand_path("./app/models/#{file}")
end


