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
    logger
  end
end

queue_name = if ENV["RACK_ENV"] == "production"
  "video-stitch-ready"
elsif ENV["RACK_ENV"] == "staging"
  "video-stitch-ready-dev"
else
  AWS.config(
      :use_ssl => false,
      :sqs_endpoint => "localhost",
      :sqs_port => 4568,
      :access_key_id =>  ENV["AWS_ACCESS_KEY_ID"],
      :secret_access_key => ENV["AWS_SECRET_ACCESS_KEY"]
  )
  "video-stitch-ready-local"
end


SQSLogger.logger.info " -- Preparing \"#{queue_name}\" SQS Queue"
queue = AWS::SQS.new.queues.create(queue_name)

class CompletePollerGroup < Celluloid::SupervisionGroup; end;
CompletePollerGroup.pool(VideoCompletePoller, as: :pollers, args: [queue], size: 5)
CompletePollerGroup.run
