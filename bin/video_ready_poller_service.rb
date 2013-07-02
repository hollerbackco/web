#!/usr/bin/env ruby

require File.expand_path(File.dirname(__FILE__) + '/../../config/environment.rb')

queue = if Sinatra::Base.production?
  AWS::SQS.new.queues.create("video-stitch-ready")
else
  AWS::SQS.new.queues.create("video-stitch-ready-dev")
end

VideoCompletePoller.new(queue).run
