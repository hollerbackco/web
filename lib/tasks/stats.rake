namespace :stats do
  desc "puts stats"
  task :get do
    ActiveRecord::Base.logger = nil
    puts "================================"
    puts "total users: #{stats.users_count}"
    puts "total conversations: #{stats.conversations_count}"
    puts "================================"
    puts "total sent: #{stats.videos_sent_count}"
    puts "total recieved: #{stats.videos_received_count}"
    puts "================================"
    puts "avg members per conversation: #{stats.members_in_conversations_avg}"
    puts "avg videos per conversation: #{stats.videos_in_conversations_avg}"
    puts "================================"
  end

  desc "cache values of the stats"
  task :cache do
    stats.uncache_all
  end

  desc "send videos to aws to compute"
  task :compute do
    Video.find_in_batches do |videos|
      messages = []
      videos.each do |video|
        messages << { message_body: {video_location: video.filename, created: videoc.created_at}.to_json }
      end
      stats.batch_enqueue messages
    end
  end

  def stats
    @stats ||= Hollerback::Statistics.new
  end
end
