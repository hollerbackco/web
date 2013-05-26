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
      upload_to_s3(file, obj)
      #obj.write(file: file)
      p s3path
      s3path
    end

    #todo temp fix to s3 upload problem
    # ref: https://github.com/aws/aws-sdk-ruby/issues/241
    def upload_to_s3(path, s3_obj)
      retries = 3
      begin
        s3_obj.write(File.open(path, 'rb', :encoding => 'BINARY'))
      rescue => ex
        retries -= 1
        if retries > 0
          puts "ERROR during S3 upload: #{ex.inspect}. Retries: #{retries left}"
          retry
        else
           # oh well, we tried...
          raise
        end
      end
    end
  end
end
