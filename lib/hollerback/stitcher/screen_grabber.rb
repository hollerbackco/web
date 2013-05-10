module Hollerback
  module Stitcher
    class ScreenGrabber
      def initialize(movie, output_file)
        @movie = movie
        @output_file = output_file
      end

      def run
        ffmpeg_movie = ::FFMPEG::Movie.new(@movie.path)

        ffmpeg_movie.screenshot @output_file

        @output_file
      end
    end
  end
end
