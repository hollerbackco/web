module Hollerback
  class Statistics
    def initialize
    end

    def conversations_count
      Conversation.all.count
    end

    def users_count
      User.all.count
    end

    def videos_sent_count
      Video.all.count
    end

    def memberships_count
      Membership.all.count
    end

    def avg_members_in_conversations_count
      if conversations_count > 0
        memberships_count.to_f / conversations_count.to_f
      else
        0
      end
    end

    def avg_videos_in_conversations_count
      if conversations_count > 0
        videos_count.to_f / conversations_count.to_f
      else
        0
      end
    end

    def videos_received_count
      Conversation.all.map do |conversation|
        (conversation.members.count - 1) * conversation.videos.count
      end.flatten.sum
    end
  end
end
