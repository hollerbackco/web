module Hollerback
  class S3Stitcher
    def initialize(files, bucketname, output_prefix="")
      @files = files
      @bucketname = bucketname
      @output_prefix = output_prefix
    end

    def run
      Dir.mktmpdir do |dir|
        files = S3Cacher.get(@files, @bucketname, dir)
        movie = Stitcher.stitch(files, output_path(dir, files), dir)
        send_movie_to_s3(movie)
      end
    end

    private

    def bucket
      @bucket ||= AWS::S3.new.buckets[@bucketname]
    end

    def output_path(dir, files)
      "#{dir}/#{File.basename(files.first).split(".").first}.mp4"
    end

    def output_s3_path(movie)
      File.join(@output_prefix, movie.random_filename)
    end

    def send_movie_to_s3(movie)
      obj = bucket.objects[output_s3_path(movie)]
      obj.write(file: movie.path)
      output_s3_path(movie)
    end
  end
end
