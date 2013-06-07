module Hollerback
  module Stitcher
    class ScreenGrabber
      def initialize(movie, output_file, size=:small)
        @movie = movie
        @output_file = output_file
        @size = size
      end

      def run
        ffmpeg_movie = ::FFMPEG::Movie.new(@movie.path)

        ffmpeg_movie.screenshot @output_file

        resize(@output_file, @size)

        @output_file
      end

      private

      def resize(filepath, size)
        image = ::MiniMagick::Image.new(filepath)
        if size == :large
          image.resize "320x320"
        else
          image.resize "90x90"
        end
      end

    end
  end
end
