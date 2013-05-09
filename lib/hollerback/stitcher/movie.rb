module Hollerback
  module Stitcher
    class Movie
      attr_accessor :path

      def initialize(path)
        raise Errno::ENOENT, "the file '#{path}' does not exist" unless File.exists?(path)
        @path = path
      end

      def filename
        File.basename(@path)
      end

      def ext
        File.extname(@path)
      end

      # filename without the extension
      def label
        filename.chomp ext
      end

      def prepare_for_stitch(prefix="tmp")
        output_file = "#{prefix}/#{label}.ts"
        t = Hollerback::Stitcher::Transcoder.new(self, output_file)
        t.run
      end

      def random_filename
        "#{SecureRandom.hex(1).upcase}/#{SecureRandom.uuid.upcase}.mp4"
      end
    end
  end
end
