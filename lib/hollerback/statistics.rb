module Hollerback
  class Statistics
    def initialize
    end

    def conversations_count
      HollerbackApp::BaseApp.settings.cache.fetch "stat-conversations-count" do
        Conversation.all.count
      end
    end

    def users_count
      HollerbackApp::BaseApp.settings.cache.fetch "stat-users-count" do
        User.all.count
      end
    end

    def videos_sent_count
      HollerbackApp::BaseApp.settings.cache.fetch "stat-videos-sent" do
        Video.all.count
      end
    end

    def memberships_count
      HollerbackApp::BaseApp.settings.cache.fetch "stat-memberships-sent" do
        Membership.all.count
      end
    end

    def members_in_conversations_avg
      HollerbackApp::BaseApp.settings.cache.fetch "stat-avg-members-per-convo-count" do
        if conversations_count > 0
          memberships_count.to_f / conversations_count.to_f
        else
          0
        end
      end
    end

    def videos_in_conversations_avg
      HollerbackApp::BaseApp.settings.cache.fetch "stat-avg-videos-per-convo-count" do
        if conversations_count > 0
          videos_sent_count.to_f / conversations_count.to_f
        else
          0
        end
      end
    end

    def videos_received_count
      HollerbackApp::BaseApp.settings.cache.fetch "stat-videos-received-count" do
        Conversation.all.map do |conversation|
          (conversation.members.count - 1) * conversation.videos.count
        end.flatten.sum
      end
    end

    def batch_enqueue(messages)
      video_compute_queue.batch_send(messages)
    end

    def uncache_all
      HollerbackApp::BaseApp.settings.cache.delete "stat-conversations-count"
      HollerbackApp::BaseApp.settings.cache.delete "stat-users-count"
      HollerbackApp::BaseApp.settings.cache.delete "stat-videos-sent"
      HollerbackApp::BaseApp.settings.cache.delete "stat-memberships-sent"
      HollerbackApp::BaseApp.settings.cache.delete "stat-avg-members-per-convo-count"
      HollerbackApp::BaseApp.settings.cache.delete "stat-avg-videos-per-convo-count"
      HollerbackApp::BaseApp.settings.cache.delete "stat-videos-received-count"
    end

    private

    def video_compute_queue
      return @queue if @queue
      @sqs = AWS::SQS.new
      @queue ||= sqs.queues.create("video:compute")
    end
  end
end
