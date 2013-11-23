class MetricsPublisher
  def self.publish(actor, topic, data={})
    if actor.is_a? User
      data = data.merge({user: actor.meta})
    end

    MetricsPublisher.delay.publish_with_delay(actor.id, topic, data)
  end

  def self.publish_with_delay(actor_id, topic, data={})
    begin
      actor = User.find(actor)
      data = data.merge({user: actor.meta})
    rescue
      puts "[error|MetricsPublisher] user does not exist"
      return
    end

    begin
      Keen.publish(topic, data)
    rescue
      puts "[error|MetricsPublisher] keen publishing error"
    end
  end
end
