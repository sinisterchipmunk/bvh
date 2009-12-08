require File.join(File.dirname(__FILE__), '../ext/bvh_ext.so') # TODO: Move this to bin
require 'bvh/matrix'
require 'bvh/motion'
require 'bvh/motion/frame'
require 'bvh/motion/channel_data'
require 'bvh/skeleton'
require 'bvh/parser'
require 'bvh/exporter'

class Bvh
  # The array of skeletons associated with this BVH.
  attr_reader :skeletons

  # The motion capture data associated with this BVH.
  attr_reader :motion

  def initialize
    @motion = Bvh::Motion.new
    @skeletons = []
  end

  # Assigns the root bone in #skeleton
  def root=(a); skeleton.root = a; end

  # Returns the root bone in #skeleton
  def root; skeleton.root; end

  # Returns the frame data associated with this BVH file.
  def frames; motion.frames; end

  # Returns the last frame associated with this animation.
  def last_frame; frames.last; end

  # Returns the amount of time, in seconds, each frame occupies. Most BVH files have this set to
  # 0.333333, which is equal to 30 frames per second.
  def frame_time; motion.frame_time; end

  # Sets the amount of time, in seconds, each frame occupies. Most BVH files have this set to
  # 0.333333, which is equal to 30 frames per second.
  def frame_time=(a); motion.frame_time = a; end

  # Returns the number of frames in the motion capture data.
  def frame_count; motion.frame_count; end

  # Returns the first skeleton in the #skeletons array.
  def skeleton; @skeletons.first; end

  # Creates a new skeleton, adds it to the #skeletons array, and returns it.
  def create_skeleton!; (@skeletons << Bvh::Skeleton.new).last; end

  class << self
    # Instantiates a new BVH and imports its data from the specified file
    def import(file)
      bvh = self.new
      parser = Bvh::Parser.new(file)
      parser.parse(bvh)
      bvh
    end
  end

  # Exports this BVH into the specified file.
  def export(file)
    exporter = Bvh::Exporter.new(file)
    exporter.export(self)
    self
  end
end
