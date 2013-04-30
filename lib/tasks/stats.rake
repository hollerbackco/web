namespace :stats do
  desc "puts stats"
  task :get do
    puts "total users: #{User.all.count}"
    puts "total conversations: #{Conversation.all.count}"
    puts "================================"
    puts "total sent: #{Video.all.count}"
    puts "total recieved: #{get_total_videos_received}"
  end

  def get_total_videos_received
    conversations = Conversation.all

    conversations.map do |conversation|
      conversation.members.count * conversation.videos.count
    end.flatten.sum
  end
end
