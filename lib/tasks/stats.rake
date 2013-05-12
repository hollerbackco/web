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
    puts "avg members per conversation: #{stats.avg_members_in_conversations_count}"
    puts "avg videos per conversation: #{stats.avg_videos_in_conversations_count}"
    puts "================================"
  end

  def stats
    @stats ||= Hollerback::Statistics.new
  end
end
