module Hollerback
  class S3Stitcher
    # s3_output_label should be the filename without an extension
    # in order that we can use it for the thumbnail.
    def initialize(files, bucketname, s3_output_label=nil)
      @files = files
      @bucketname = bucketname
      @s3_output_label = s3_output_label || Hollerback::Stitcher::Movie.random_label
    end

    def run
      Dir.mktmpdir do |dir|
        files = S3Cacher.get(@files, @bucketname, dir)
        movie = Stitcher.stitch(files, output_path(dir, files), dir)

        image = movie.screengrab(dir)

        send_file_to_s3(image, "#{@s3_output_label}-thumb.png")
        video_path = send_file_to_s3(movie.path, "#{@s3_output_label}.mp4")

        video_path
      end
    end

    private

    def bucket
      @bucket ||= AWS::S3.new.buckets[@bucketname]
    end

    def output_path(dir, files)
      "#{dir}/#{File.basename(files.first).split(".").first}.mp4"
    end

    def send_file_to_s3(file, s3path)
      obj = bucket.objects[s3path]
      obj.write(file: file)
      s3path
    end
  end
end
