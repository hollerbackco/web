#this class Reactivates users
class Reactivator
  include Sidekiq::Worker

  class Track #todo change name to track

    attr_accessor :name, :level_info

    def get_name
      return @name
    end

    def start_track
    end

    #must be overriden
    def users_meeting_track_criteria
    end

    def get_users_on_track
      User.joins(:reactivation).where("reactivations.track = ?", @name)
    end

    def eligible_for_next_level?(user)
      current_level = @level_info[user.reactivation.track_level]
      next_level = @level_info[current_level[:next_level]]

      is_eligible = (user.reactivation.last_reactivation < Level.get_target_date(next_level))
      p "is user eligible: " + is_eligible.to_s

      is_eligible
    end

    #puts a user on the next
    def put_on_next_level(user)
      current_level = @level_info[user.reactivation.track_level]
      next_level = current_level[:next_level]
      user.reactivation.track_level = next_level
      user.reactivation.last_reactivation = Time.now
      user.save
    end

    def get_level_message
    end

    class Level
      INACTIVE_DAY_1 = "inactive_day_1"
      INACTIVE_DAY_2 = "inactive_day_2"
      INACTIVE_DAY_3 = "inactive_day_3"
      INACTIVE_DAY_7 = "inactive_day_7"
      INACTIVE_DAY_14 = "inactive_day_14"
      INACTIVE_DAY_21 = "inactive_day_21"

      def self.get_target_date(level)
        case (level)
          when INACTIVE_DAY_1
            (DateTime.now - 1)
          when INACTIVE_DAY_2
            (DateTime.now - 2)
          when INACTIVE_DAY_3
            (DateTime.now - 3)
          when INACTIVE_DAY_7
            (DateTime.now - 7)
          when INACTIVE_DAY_14
            (DateTime.now - 14)
          when INACTIVE_DAY_21
            (DateTime.now - 21)
        end
      end
    end

  end

  class VideoTrack < Track
    NAME = "video"
    LEVEL_INFO = {
        Track::Level::INACTIVE_DAY_1 => {:message => "You have a video waiting for you", :next_level => Track::Level::INACTIVE_DAY_3},
        Track::Level::INACTIVE_DAY_3 => {:message => "You have a video waiting for you", :next_level => Track::Level::INACTIVE_DAY_7},
        Track::Level::INACTIVE_DAY_7 => {:message => "You have unwatched videos", :next_level => Track::Level::INACTIVE_DAY_14},
        Track::Level::INACTIVE_DAY_14 => {:message => "You have unwatched videos", :next_level => Track::Level::INACTIVE_DAY_21},
        Track::Level::INACTIVE_DAY_21 => {:message => "You have unwatched videos", :next_level => Track::Level::INACTIVE_DAY_21},
    }

    def initialize
      @name = NAME
      @level_info = LEVEL_INFO
    end

    def users_meeting_track_criteria
    end


  end

  class WatchedNotSentTrack < Track
    NAME = "watched_not_sent"
    LEVEL_INFO = {
        Track::Level::INACTIVE_DAY_1 => {:message => "Did you know we have costumes, groups, to make fun videos?", :next_level => Track::Level::INACTIVE_DAY_3},
        Track::Level::INACTIVE_DAY_3 => {:message => "Hollerback is great with friends and family, send a video", :next_level => Track::Level::INACTIVE_DAY_7},
        Track::Level::INACTIVE_DAY_7 => {:message => "Come back", :next_level => Track::Level::INACTIVE_DAY_14},
        Track::Level::INACTIVE_DAY_14 => {:message => "Come back", :next_level => Track::Level::INACTIVE_DAY_21},
        Track::Level::INACTIVE_DAY_21 => {:message => "Come back", :next_level => Track::Level::INACTIVE_DAY_21}
    }

    def initialize
      @name = NAME
    end

    def users_meeting_track_criteria
    end


  end

  class WatchedSentNoGroupTrack < Track
    NAME = "watched_sent_no_group"
    LEVEL_INFO = {
        Track::Level::INACTIVE_DAY_2 => {:message => "Create group messages", :next_level => Track::Level::INACTIVE_DAY_7},
        Track::Level::INACTIVE_DAY_7 => {:message => "Did you know we have costumes, groups, to make fun videos?", :next_level => Track::Level::INACTIVE_DAY_14},
        Track::Level::INACTIVE_DAY_14 => {:message => "Come back", :next_level => Track::Level::INACTIVE_DAY_21},
        Track::Level::INACTIVE_DAY_21 => {:message => "Come back", :next_level => Track::Level::INACTIVE_DAY_21},
    }

    def initialize
      @name = NAME
      @level_info = LEVEL_INFO
    end

    def users_meeting_track_criteria
    end


  end

  class WatchedSentGroupNoSoloTrack < Track
    NAME = "watched_sent_group_no_solo"
    LEVEL_INFO = {
        Track::Level::INACTIVE_DAY_1 => {:message => "You have a video waiting for you", :next_level => Track::Level::INACTIVE_DAY_3},
        Track::Level::INACTIVE_DAY_3 => {:message => "You have a video waiting for you", :next_level => Track::Level::INACTIVE_DAY_7},
        Track::Level::INACTIVE_DAY_7 => {:message => "You have unwatched videos", :next_level => Track::Level::INACTIVE_DAY_14},
        Track::Level::INACTIVE_DAY_14 => {:message => "You have unwatched videos", :next_level => Track::Level::INACTIVE_DAY_21},
        Track::Level::INACTIVE_DAY_21 => {:message => "You have unwatched videos", :next_level => Track::Level::INACTIVE_DAY_21},
    }

    def initialize
      @name = NAME
      @level_info = LEVEL_INFO
    end

    def users_meeting_track_criteria
    end

  end

  class WatchedSentBothTrack < Track
    NAME = "watched_sent_both"
    LEVEL_INFO = {
        Track::Level::INACTIVE_DAY_7 => {:message => "Come back"},
        Track::Level::INACTIVE_DAY_14 => {:message => "Come back"},
        Track::Level::INACTIVE_DAY_21 => {:message => "Come back"},
    }

    def initialize
      @name = NAME
      @level_info = LEVEL_INFO
    end

    def users_meeting_track_criteria
    end

  end

  #add a dry run flag
  def perform(dry_run)
    begin #don't crash production
      @dry_run = dry_run
      @tracks = [Track::VideoTrack.new, Track::WatchedNotSentTrack.new, WatchedSentNoGroupTrack.new, WatchedSentGroupNoSoloTrack.new, WatchedSentBothTrack.new]

      #get all users on a track and put them on a track_level
      update_user_track()


      #The following will process users that aren't on a track

      #get all the users that haven't been active for over 24hrs that don't have a reactivation track
      users_not_on_a_track = User.where("users.last_active_at is not null AND users.last_active_at < :target_date AND users.id not in (select user_id from reactivations)", {:target_date => (DateTime.now - 1.5)})
      put_on_track(users_not_on_a_track)
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
    end

  end

  #update the current user tracks
  def update_user_track

    eligible_group = @tracks.map do |track|
      users = track.get_users_on_track #get all the user on this track
      eligible_users = users.reduce([]) do |eligible_users, user| # reduce the userbase to users who's track has been updated
        if (track.eligible_for_next_level?(user))
          put_on_next_level(user) #put the user on the next level
          eligible_users << user
        end
        eligible_users
      end
      {track: track, users: eligible_users}
    end

    push(eligible_group)

    #TODO: Send push to these users
    #push_to_users(prepare_push(users_to_reactivate))
  end

  def push(eligible_group)

  end

  def get_next_video_track(current_track)

    index = @tracks.video_track.index(@tracks.video_track.detect { |track| track.has_key?(current_track) })

    if (index + 1 < @tracks.video_track.size)
      @tracks.video_track[index + 1]
    else
      @tracks.video_track[index]
    end
  end

  def get_next_engagement_track(current_track)

    index = @tracks.engagement_track.index(@tracks.engagement_track.detect { |track| track.has_key?(current_track) })

    if (index + 1 < @tracks.engagement_track.size)
      @tracks.engagement_track[index + 1]
    else
      @tracks.engagement_track[index]
    end
  end

  def update_enagement_track(users)

    return [] unless users.any?

    users.reduce([]) do |push_users, user|

      next_track = get_next_engagement_track(user.reactivation.track_level)
      if (user.reactivation.last_reactivation <= next_track[next_track.keys[0]][:target_date])

        user.reactivation.last_reactivation = Time.now
        user.reactivation.track_level = next_track.keys[0] #next_track.keys[0] is one of VIDEO_DAY_1, ..
        user.reactivation.save

        push_users << user
      end

      push_users
    end
  end

  def update_video_track(users)

    return [] unless users.any?

    users.reduce([]) do |push_users, user|

      next_track = get_next_video_track(user.reactivation.track_level)
      if (user.reactivation.last_reactivation <= next_track[next_track.keys[0]][:target_date])

        user.reactivation.last_reactivation = Time.now
        user.reactivation.track_level = next_track.keys[0] #next_track.keys[0] is one of VIDEO_DAY_1, ..
        user.reactivation.save

        push_users << user
      end

      push_users
    end
  end

  #put the users on a track
  def put_on_track(users)
    #split the users to see what track we should put them on, video or engagement track
    #SQL: SELECT "users".* FROM "users" INNER JOIN "memberships" ON "memberships"."user_id" = "users"."id" INNER JOIN "messages" ON "messages"."membership_id" = "memberships"."id" WHERE (messages.seen_at is null)
    video_track_users = users.joins(:memberships => :messages).where("messages.seen_at is null AND content ? 'guid' AND is_sender IS NOT TRUE").uniq_by { |u| u.id }
    engagement_track_users = users - video_track_users


    put_on_video_track(video_track_users)
    put_on_engagement_track(engagement_track_users)

    push_to_users(prepare_push(video_track_users.concat(engagement_track_users)))
  end

  def put_on_video_track(users)
    Reactivation.transaction do
      users.each do |user|
        if (user.reactivation.nil?)
          user.reactivation = Reactivation.create(:track => Tracks::VIDEO_TRACK, :track_level => Tracks::VIDEO_DAY_1)
        else
          user.reactivation.track = Tracks::VIDEO_TRACK
          user.reactivation.track_level = Tracks::VIDEO_DAY_1
        end
        user.reactivation.last_reactivation = Time.now
        user.reactivation.save
      end
    end
  end

  def put_on_engagement_track(users)
    Reactivation.transaction do
      users.each do |user|
        if (user.reactivation.nil?)
          user.reactivation = Reactivation.create(:track => Tracks::ENGAGEMENT_TRACK, :track_level => Tracks::ENGAGEMENT_DAY_3)
        else
          user.reactivation.track = Tracks::ENGAGEMENT_TRACK
          user.reactivation.track_level = Tracks::ENGAGEMENT_DAY_3
        end
        user.reactivation.last_reactivation = Time.now
        user.reactivation.save

      end
    end
  end

  #prepare users for push by bundling users with the appropriate message
  def prepare_push(users)
    users.reduce([]) do |push_list, user|
      #get the user reactivation
      reactivation = user.reactivation

      track = {}
      if (reactivation)
        if (reactivation.track == Tracks::VIDEO_TRACK)
          track = @tracks.video_track.detect { |track| track.has_key?(reactivation.track_level) }
        else
          track = @tracks.engagement_track.detect { |track| track.has_key?(reactivation.track_level) }
        end

        track_detail = track[reactivation.track_level]

        message = track_detail[:message]
        has_params = track_detail[:has_params]
        if (has_params)
          num_params = track_detail[:num_params]

          params = []
          for i in 1..num_params

            param_type_key = "param#{i}_type"
            param_type = track_detail[param_type_key.to_sym]

            case param_type
              when 'video_sender' # this is way way too slow; need to find an alternative
                unseen = user.unseen_messages
                if (unseen.any?)
                  sender_name = unseen.first.sender_name
                  params << sender_name
                else
                  params << "a friend"
                end
            end

          end

          message = message % params
          p message
        end

        push_list << {:user => user, :message => message}
      end
      p message
      push_list
    end
  end

  def push_to_users(push_payload)
    unless @dry_run
      p 'the real deal'
      push_payload.each do |user_info|
        user = user_info[:user]
        message = user_info[:message]

        Hollerback::Push.send(nil, user.id, {
            alert: message,
            sound: "default"
        }.to_json)

        tokens = user.devices.android.map { |device| device.token }
        payload = {:message => message}
        if (!tokens.empty?)
          Hollerback::GcmWrapper.send_notification(tokens, Hollerback::GcmWrapper::TYPE::NOTIFICATION, payload)
        end

        data = {
            track: user.reactivation.track,
            track_level: user.reactivation.track_level
        }

        MetricsPublisher.publish(user, "push:reengage", data)

      end
    else
      p 'dry run'
    end
  end

end