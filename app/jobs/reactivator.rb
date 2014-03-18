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
                            {VIDEO_DAY_1 => (DateTime.now - 1)},
                            {VIDEO_DAY_3 => (DateTime.now - 3)},
                            {VIDEO_DAY_7 => (DateTime.now - 7)},
                            {VIDEO_DAY_12 => (DateTime.now - 12)},
                            {VIDEO_DAY_21 => (DateTime.now - 21)}
                          ]
      @engagement_track = [
                            {ENGAGEMENT_DAY_3 => (DateTime.now - 3)},
                            {ENGAGEMENT_DAY_7 => (DateTime.now - 7)},
                            {ENGAGEMENT_DAY_14 => (DateTime.now - 14)},
                            {ENGAGEMENT_DAY_21 => (DateTime.now - 21)},
                            {ENGAGEMENT_DAY_30 => (DateTime.now - 30)}
                          ]
    end

  end

  #add a dry run flag
  def perform()

    #get all users on a track and put them on a track_level
    users_on_a_track = User.joins(:reactivation)
    update_user_track(users_on_a_track)


    #The following will process users that aren't on a track

    #get all the users that haven't been active for over 24hrs that don't have a reactivation track
    users_not_on_a_track = User.where("users.last_active_at is not null AND users.last_active_at < :target_date AND users.id not in (select user_id from reactivations)", {:target_date => (DateTime.now - 1)})
    put_on_track(users_not_on_a_track)

  end

  #update the current user tracks
  def update_user_track(users)
    #lets find each users track and update them
    video_track_users = users.joins(:reactivation).where(:track => VIDEO_TRACK)
    engagement_track_users = users.join(:reactivation).where(:track => ENGAGEMENT_TRACK)

    update_video_track(video_track_users)
    update_enagement_track(engagement_track_users)


  end

  def update_enagement_track(users)

  end

  def update_video_track(users)
    push_users = users.reduce([]) do |push_users, user|

      case user.reactivation.track_level
        when VIDEO_DAY_1
          #do this
        when VIDEO_DAY_3
          #do this
        when VIDEO_DAY_7
          #do this
        when VIDEO_DAY_12
          #do this
        when VIDEO_DAY_21
          #do this
      end

      push_users
    end

  end

  #put the users on a track
  def put_on_track(users)
    #split the users to see what track we should put them on, video or engagement track
    #SQL: SELECT "users".* FROM "users" INNER JOIN "memberships" ON "memberships"."user_id" = "users"."id" INNER JOIN "messages" ON "messages"."membership_id" = "memberships"."id" WHERE (messages.seen_at is null)
    video_track_users = users.joins(:memberships => :messages).where('messages.seen_at is null').uniq_by {|u| u.id}
    put_on_video_track(video_track_users)


    engagement_track_users = users.joins(:memberships => :messages).where('messages.seen_at is not null').uniq_by {|u| u.id}
    put_on_engagement_track(engagement_track_users)
  end

  def put_on_video_track(users)

  end

  def put_on_engagement_track(users)

  end

end