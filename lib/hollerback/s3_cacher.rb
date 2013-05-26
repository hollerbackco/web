module Hollerback
  class S3Cacher
    def initialize(key, bucketname, tmpdir="tmp")
      @s3path = key
      @tmpdir = tmpdir
      @bucket = AWS::S3.new.buckets[bucketname]
      cache!
    end

    def cache!
      File.open(cached_path, "wb") do |f|
        f.write(@bucket.objects[@s3path].read)
      end
    end

    def cached_path
      "#{@tmpdir}/#{filename}"
    end

    def filename
      File.basename(@s3path)
    end

    def self.get(videos, bucketname, tmpdir)
      videos.map {|v| self.new(v, bucketname, tmpdir).cached_path }
    end
  end
end
