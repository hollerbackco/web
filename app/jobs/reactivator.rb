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

    def get_initial_level
    end

    #must be overriden
    def users_meeting_track_criteria
    end

    def get_users_on_track
      User.joins(:reactivation).where("reactivations.track = ?", @name)
    end

    def eligible_for_next_level?(user)
      current_level = @level_info[user.reactivation.track_level]
      next_level_key = current_level[:next_level]

      is_eligible = (user.reactivation.last_reactivation < Level.get_target_date(next_level_key))
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


    #This method will chose all the eligible users passed in that are eligible for the track and return an array of users
    #Subclasses must override this method
    def get_users_eligible_for_track(users)
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

    def get_users_eligible_for_track(users)
      #ensure that the unread isn't from will from hollerback
      users.joins(:memberships => :messages).where("messages.seen_at is null AND content ? 'guid' AND is_sender IS NOT TRUE AND sender_id != 889").uniq_by { |u| u.id }
    end

    def get_initial_level_key
      Track::Level::INACTIVE_DAY_1
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
      @level_info = LEVEL_INFO
    end

    #note: not checking for the watched state which is incorrect. But since we'll be only passing in users that
    # as a precondition have been filtered by other tracks, then there's no need
    def get_users_eligible_for_track(users)
      #select users that have not sent
      users.joins("left outer join messages on users.id = messages.sender_id").where("messages.sender_id is null")
    end

    def get_initial_level_key
      Track::Level::INACTIVE_DAY_1
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

    #get users who haven't created a group
    def get_users_eligible_for_track(users)
      #not that easy to do..hmm?
      []
    end

    def get_initial_level_key
      Track::Level::INACTIVE_DAY_2
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

    def get_users_eligible_for_track(users)
      #not that easy to do..hmm?
      []
    end

    def get_initial_level_key
      Track::Level::INACTIVE_DAY_1
    end

  end

  class WatchedSentBothTrack < Track
    NAME = "watched_sent_both"
    LEVEL_INFO = {
        Track::Level::INACTIVE_DAY_7 => {:message => "Come back", :next_level => Track::Level::INACTIVE_DAY_14},
        Track::Level::INACTIVE_DAY_14 => {:message => "Come back", :next_level => Track::Level::INACTIVE_DAY_21},
        Track::Level::INACTIVE_DAY_21 => {:message => "Come back", :next_level => Track::Level::INACTIVE_DAY_21},
    }

    def initialize
      @name = NAME
      @level_info = LEVEL_INFO
    end

    def get_users_eligible_for_track(users)
      users #just return the remaining users
    end

    def get_initial_level_key
      Track::Level::INACTIVE_DAY_7
    end

  end

  #add a dry run flag
  def perform(dry_run)
    begin #don't crash production
      @dry_run = dry_run
      @tracks = [VideoTrack.new, WatchedNotSentTrack.new, WatchedSentNoGroupTrack.new, WatchedSentGroupNoSoloTrack.new, WatchedSentBothTrack.new]

      #get all users on a track and put them on a track_level
      update_user_track()

      #get all the users that haven't been active for over 24hrs that don't have a reactivation track
      users_not_on_a_track = User.where("users.last_active_at is not null AND users.last_active_at < :target_date AND users.id not in (select user_id from reactivations)", {:target_date => (DateTime.now - 1.5)})
      p "eligible users not on a track: #{users_not_on_a_track.count}"
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
    #todo fill in with push stuff
  end

  #put the users on a track
  def put_on_track(users)

    #for each of the existing tracks find the appropriate track for these users
    track_groups = @tracks.map do |track|

      eligible = track.get_users_eligible_for_track(users)
      p "processing batch #{track.name} with #{eligible.count} users"
      eligible.each do |user|

        reactivation = Reactivation.where(:user_id => user.id).first_or_create
        reactivation.track = track.name
        reactivation.track_level = track.get_initial_level_key
        reactivation.last_reactivation = DateTime.now
        reactivation.save
      end
      unless eligible.blank?
        users = users.where("users.id not in (?)", eligible.map {|user| user.id}) #subtract this group for the next group
      end
      {track: track, users: eligible}
    end

    push_to_users(prepare_push(track_groups))
  end


  #prepare users for push by bundling users with the appropriate message
  def prepare_push(track_groups)

    push_list = []
    track_groups.each do |group|
      p group
      track = group[:track]
      users = group[:users]
      users.each do |user|
        push_list << {:user => user, :message => track.level_info[user.reactivation.track_level][:message]}
      end
    end
    push_list
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