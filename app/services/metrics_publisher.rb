class MetricsPublisher
  def self.publish(actor, topic, data={})
    if actor.is_a? User
      data = data.merge({user: actor.meta})
    elsif actor.is_a? Hash
      data = data.merge({user: actor})
    end

    begin
      Keen.publish(topic, data)
    rescue
      puts "[error] keen publishing error"
    end
  end
end
