class MetricsPublisher
  def self.publish(actor, topic, data={})
    data = data.merge({user: actor.meta})

    Keen.publish(topic, data)
  end
end
