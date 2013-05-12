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

        random_label = Hollerback::Stitcher::Movie.random_label

        image = movie.screengrab(dir)

        send_file_to_s3(image, "#{random_label}-thumb.png")
        video_path = send_file_to_s3(movie.path, "#{random_label}.mp4")

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
