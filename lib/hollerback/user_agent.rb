module Hollerback
  class UserAgent
    module Platform
      Windows       = /windows/i
      Mac           = /macintosh/i
      Linux         = /linux/i
      Wii           = /wii/i
      Playstation   = /playstation/i
      Ipad          = /ipad/i
      Ipod          = /ipod/i
      Iphone        = /iphone/i
      Android       = /android/i
      Blackberry    = /blackberry/i
      WindowsPhone  = /windows (ce|phone|mobile)( os)?/i
      Symbian       = /symbian(os)?/i
    end

    def self.platform(string)
      case string
      when Platform::Android  then :android
      when Platform::Ipad     then :ipad
      when Platform::Ipod     then :ipod
      when Platform::Iphone   then :iphone
      else
        :other
      end
    end

    attr_accessor :source

    def initialize(source)
      @source = source
    end

    def ios?
      [:iphone, :ipad, :ipod].include?(platform)
    end

    def platform
      @platform ||= self.class.platform(source)
    end
  end
end
