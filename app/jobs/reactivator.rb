#this class Reactivates
class Reactivator
  include Sidekiq::Worker


  class Tracks

    VIDEO_TRACK = "video"
    ENGAGEMENT_TRACK = "engagement"

    VIDEO_DAY_1 = "video_day_1"
    VIDEO_DAY_3 = "video_day_3"
    VIDEO_DAY_7 = "video_day_7"
    VIDEO_DAY_12 = "video_day_12"
    VIDEO_DAY_21 = "video_day_21"

    ENGAGEMENT_DAY_3 = "engagement_day_3"
    ENGAGEMENT_DAY_7 = "engagement_day_7"
    ENGAGEMENT_DAY_14= "engagement_day_14"
    ENGAGEMENT_DAY_21 = "engagement_day_21"
    ENGAGEMENT_DAY_30 = "engagement_day_30"


    attr_accessor :video_track, :engagement_track

    def initialize
      @video_track =      [
                            {VIDEO_DAY_1 => {:target_date => (DateTime.now - 1)}},
                            {VIDEO_DAY_3 => {:target_date => (DateTime.now - 3)}},
                            {VIDEO_DAY_7 => {:target_date => (DateTime.now - 7)}},
                            {VIDEO_DAY_12 =>{:target_date => (DateTime.now - 12)}},
                            {VIDEO_DAY_21 =>{:target_date => (DateTime.now - 21)}}
                          ]
      @engagement_track = [
                            {ENGAGEMENT_DAY_3 =>  {:target_date => (DateTime.now - 3)}},
                            {ENGAGEMENT_DAY_7 =>  {:target_date => (DateTime.now - 7)}},
                            {ENGAGEMENT_DAY_14 => {:target_date => (DateTime.now - 14)}},
                            {ENGAGEMENT_DAY_21 => {:target_date => (DateTime.now - 21)}},
                            {ENGAGEMENT_DAY_30 => {:target_date => (DateTime.now - 30)}}
                          ]
    end

  end

  def initialize
    @tracks = Tracks.new
  end

  #add a dry run flag
  def perform()
    @tracks = Tracks.new

    #get all users on a track and put them on a track_level
    users_on_a_track = User.joins(:reactivation)
    update_user_track(users_on_a_track)


    #The following will process users that aren't on a track

    #get all the users that haven't been active for over 24hrs that don't have a reactivation track
    users_not_on_a_track = User.where("users.last_active_at is not null AND users.last_active_at < :target_date AND users.id not in (select user_id from reactivations)", {:target_date => (DateTime.now - 1)})
    put_on_track(users_not_on_a_track)

  end

  def get_next_video_track(current_track)

    index = @tracks.video_track.index(@tracks.video_track.detect {|track| track.has_key?(current_track)})

    if(index + 1 < @tracks.video_track.size)
      @tracks.video_track[index + 1]
    else
      @tracks.video_track[index]
    end
  end

  def get_next_engagement_track(current_track)

    index = @tracks.engagement_track.index(@tracks.engagement_track.detect {|track| track.has_key?(current_track)})

    if(index + 1 < @tracks.engagement_track.size)
      @tracks.engagement_track[index + 1]
    else
      @tracks.engagement_track[index]
    end
  end

  #update the current user tracks
  def update_user_track(users)
    #lets find each users track and update them
    video_track_users = users.joins(:reactivation).where("reactivations.track = ?", Tracks::VIDEO_TRACK)
    engagement_track_users = users.joins(:reactivation).where("reactivations.track = ?", Tracks::ENGAGEMENT_TRACK)

    users_to_reactivate = []

    users_to_reactivate.concat(update_video_track(video_track_users))
    users_to_reactivate.concat(update_enagement_track(engagement_track_users))

    #TODO: Send push to these users
    push_to_users(users_to_reactivate)
  end

  def update_enagement_track(users)

    return [] unless users.any?

    users.reduce([]) do |push_users, user|

      next_track = get_next_engagement_track(user.reactivation.track_level)
      if(user.reactivation.last_reactivation <= next_track[next_track.keys[0]][:target_date])

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
      if(user.reactivation.last_reactivation <= next_track[next_track.keys[0]][:target_date])

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
    video_track_users = users.joins(:memberships => :messages).where('messages.seen_at is null').uniq_by {|u| u.id}
    engagement_track_users = users.joins(:memberships => :messages).where('messages.seen_at is not null').uniq_by {|u| u.id}


    put_on_video_track(video_track_users)
    put_on_engagement_track(engagement_track_users)

    push_to_users(video_track_users.concat(engagement_track_users))
  end

  def put_on_video_track(users)
    Reactivation.transaction do
      users.each do |user|
        if(user.reactivation.nil?)
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
        if(user.reactivation.nil?)
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

  def push_to_users(users)
      p users
  end

end