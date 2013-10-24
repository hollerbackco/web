module Hollerback
  class Push
    class << self
      def configure(pemfile, is_production=false)
        @client = self.client(pemfile, is_production)
      end

      def send(token, options={})
        alert = options[:alert]
        badge = options[:badge]
        sound = options[:sound]
        content_available = options[:content_available]

        notification = Houston::Notification.new(device: token)
        notification.alert = alert if alert
        notification.badge = badge if badge
        notification.sound = sound if sound
        notification.content_available = content_available if content_available

        @client.push(notification)
      end

      def client(pemfile, is_production)
        client = is_production ? Houston::Client.production : Houston::Client.development
        client.certificate = File.read(pemfile)
        client
      end
    end
  end
end
