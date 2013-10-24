module Hollerback
  class Push
    class << self
      def configure(pemfile, is_production=false)
        @client = self.client(pemfile, production)
      end

      def send(token, options={})
        alert = options[:alert]
        badge = options[:badge]
        sound = options[:sound]

        notification = Houston::Notification.new(device: token)
        notification.alert = alert if alert
        notification.badge = badge if badge
        notification.sound = sound if sound

        self.client.push(notification)
      end

      def client(pemfile, is_production)
        return @client if @client
        client = is_production ? Houston::Client.production : Houston::Client.development
        client.certificate = File.read(pemfile)
        @client = client
      end
    end
  end
end
