#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../config/environment.rb')

$stdout.sync = true

module SQSLogger
  def self.logger
    @logger ||= self.create_logger
  end

  def self.create_logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO
  end
end

queue_name = if Sinatra::Base.production?
  "video-stitch-ready"
else
  "video-stitch-ready-dev"
end

SQSLogger.logger.info " -- Preparing \"#{queue_name}\" SQS Queue"
queue = AWS::SQS.new.queues.create()

VideoCompletePoller.new(queue).run
