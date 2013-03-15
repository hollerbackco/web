#require "remote_store/configuration"

module Hollerback
  module RemoteStore
    class << self
      attr_accessor :bucket_name
    end

    module Base
      #include Hollerback::RemoteStore::Configuration
    end
  end
end
