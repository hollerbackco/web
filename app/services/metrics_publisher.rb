class MetricsPublisher
  def self.publish(actor, topic, data={})
    MetricsPublisher.delay.publish_with_delay(actor.id, topic, data)
  end

  def self.publish_with_delay(actor_id, topic, data={})
    if actor.is_a? User
      data = data.merge({user: actor.meta})
    elsif actor.is_a? Hash
      data = data.merge({user: actor})
    elsif actor.is_a? Integer
      begin
        actor = User.find(actor)
        data = data.merge({user: actor.meta})
      rescue
        puts "[error|MetricsPublisher] user does not exist"
        return
      end
    end

    begin
      Keen.publish(topic, data)
    rescue
      puts "[error|MetricsPublisher] keen publishing error"
    end

  end
end
