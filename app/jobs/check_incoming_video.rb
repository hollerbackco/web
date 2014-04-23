class CheckIncomingVideo
  include Sidekiq::Worker

  def self.get_cache_key(convo_id, guid)
    "#{convo_id}:#{guid}"
  end

  def perform(convo_id, guid, dry_run=false)
    #look up redis
    payload = JSON.parse(REDIS.get(get_cache_key(convo_id, guid)))

    p payload.to_s
    if(payload["processed"] == false)
      p "incoming video has not been processed"
      #notify user
      if(!dry_run)
        Hollerback::Push.send(nil, payload["sender_id"], {:alert => "Failed to upload video", :sound => "default"}.to_json)
      else
        p "dry run push on incoming"
      end
    else
      p "incoming video processed"
    end
  end

end