module Hollerback
  module Stitcher
    class Transcoder
      def initialize(movie, output_file)
        @movie = movie
        @output_file = output_file
        @ffmpeg_options = "-c copy -bsf:v h264_mp4toannexb -f mpegts"
      end

      def run
        ffmpeg_movie = ::FFMPEG::Movie.new(@movie.path)

        ffmpeg_movie.transcode @output_file, @ffmpeg_options

        Movie.new(@output_file)
      end
    end
  end
end
