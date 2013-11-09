module Hollerback
  class Push
    class << self
      def configure(pemfile, is_production=false, app_root)
        @app_root = app_root
        @client = self.client(pemfile, is_production)
        if is_production
          @appstore_client = appstore_client
        end
      end

      def send(token, options={})
        alert = options[:alert]
        badge = options[:badge]
        sound = options[:sound]
        data = options[:data]
        content_available = options[:content_available]

        notification = Houston::Notification.new(device: token)
        notification.alert = alert if alert
        notification.badge = badge if badge
        notification.sound = sound if sound
        notification.custom_data = data if data
        notification.content_available = content_available if content_available
        @client.push(notification)

        notification = Houston::Notification.new(device: token)
        notification.alert = alert if alert
        notification.badge = badge if badge
        notification.sound = sound if sound
        notification.custom_data = data if data
        notification.content_available = content_available if content_available
        @appstore_client.push(notification) if @appstore_client
      end

      def client(pemfile, is_production)
        client = is_production ? Houston::Client.production : Houston::Client.development
        client.certificate = File.read(pemfile)
        client
      end

      def appstore_client
        client = Houston::Client.production
        pemfile = File.join(@app_root, 'config', 'apns', 'apns_prod.pem')
        client.certificate = File.read(pemfile)
        client
      end
    end
  end
end
