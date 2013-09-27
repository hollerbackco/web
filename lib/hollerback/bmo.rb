module Hollerback
  class BMO
    def self.say(msg)
      uri = URI('http://still-depths-4143.herokuapp.com/hubot/say')
      res = Net::HTTP.post_form(uri, 'room' => '60453_hollerback@conf.hipchat.com', 'message' => msg)
    end
  end
end
