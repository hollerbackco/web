module Hollerback
  class NotifyRecipients
    def initialize(video)
      @recipients = video.conversation.members - [video.user]
      @video = video
    end

    def run
      @recipients.each {|r| notify @video, r}
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
          alert: "#{video.user.name}",
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
  end
end
