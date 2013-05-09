$LOAD_PATH.unshift File.dirname(__FILE__)

require 'logger'
require 'stringio'

require 'stitcher/version'
require 'stitcher/movie'
require 'stitcher/transcoder'

module Hollerback
  module Stitcher
    # Set the path of the ffmpeg binary.
    # Can be useful if you need to specify a path such as /usr/local/bin/ffmpeg
    #
    # @param [String] path to the ffmpeg binary
    # @return [String] the path you set
    def self.ffmpeg_binary=(bin)
      @ffmpeg_binary = bin
    end

    # Get the path to the ffmpeg binary, defaulting to 'ffmpeg'
    #
    # @return [String] the path to the ffmpeg binary
    def self.ffmpeg_binary
      @ffmpeg_binary || 'ffmpeg'
    end

    # Get the path to the ffmpeg binary, defaulting to 'ffmpeg'
    #
    # @return [Movie] get path to get the location of the output file
    def self.stitch(files, output_file, output_dir)
      prepared = files.map { |file| Movie.new(file).prepare_for_stitch(output_dir).path }
      command = "ffmpeg -i \"concat:"
      command << prepared.join("|")
      command << "\" -c copy -bsf:a aac_adtstoasc "
      command << output_file

      Open3.popen3(command) { |stdin, stdout, stderr| stderr.read }

      Movie.new(output_file)
    end
  end
end
