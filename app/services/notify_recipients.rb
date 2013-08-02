module Hollerback
  class NotifyRecipients
    def initialize(video)
      @video = video
      @recipients = video.recipients
    end

    def run
      @recipients.each do |recipient|
        notify @video, recipient
        touch_cache recipient
      end
    end

    private

    def notify(video, person)
      data = {
        conversation_id: video.conversation.id,
        video_id: video.id,
        sender_name: video.user.name
      }
      badge_count = person.unread_videos.count

      person.devices.ios.each do |device|
        APNS.send_notification(device.token, {
          alert: video.user.also_known_as(for: person),
          badge: badge_count,
          sound: "default",
          other: {
            hb: data
          }
        })
      end

      person.devices.android.each do |device|
        ::GCMS.send_notification([device.token],
          data: data
        )
      end
    end

    def touch_cache(user)
      user.memcache_key_touch
    end
  end
end
