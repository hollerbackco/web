Hollerback::MQTT.configure do |config|
  config.client_options = {
    remote_host: ENV['MQTT_HOST'],
    username: ENV['MQTT_USERNAME'],
    password: ENV['MQTT_PASSWORD']
  }

  config.encrypt_key = ENV['XTEA_KEY']
end
