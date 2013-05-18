module Hollerback
  class Stat
    def self.conversations_time_series
      Keen.count
    end
  end
end
