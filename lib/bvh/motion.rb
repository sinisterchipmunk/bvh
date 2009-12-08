class Bvh
  class Motion
    # The amount of time that passes for each frame. Most BVH files have this set to 0.0333, or 30 frames per second.
    # The following calculations might also be useful to you:
    #    frame_time = 1 / frames_per_second   # =>  0.0333 = 1 / 30
    #    frames_per_second = 1 / frame_time   # =>  30 = 1 / 0.0333
    attr_accessor :frame_time

    # The array of frames in this animation. You can modify this directly if you wish.
    attr_reader :frames

    def initialize
      @frames = []
    end

    # Returns the number of frames in this animation.
    def frame_count
      frames.length
    end

    # Adds the specified frame or frames to the end of this animation.
    def add_frame(*frames)
      self.frames.concat frames.flatten
    end

    # Creates a single frame that is an exact copy of the last frame in this animation.
    def create_frame
      frames.last.copy
    end

    # Creates N frames via #create_frame.
    def create_frames(n)
      r = []
      n.times { r << create_frame }
      r
    end

    # Creates enough frames to fill the specified number of seconds, adds them to the animation, and returns self.
    #
    # target_frame is the state at which the animation should be in upon reaching the final frame of the alotted time.
    # If it contains data that is different from the last frame in this animation, then the result will be an
    # interpolation between the two over the course of the alotted time.
    #
    # You can use this method to specify key points in the animation, and produce a fluid result.
    def add_time(seconds, target_frame = frames.last)
      raise "Can't calculate frames from seconds: frame_time is zero!" if frame_time == 0
      num_frames = (seconds / frame_time).to_i
      return self if num_frames == 0

      # buf holds the amount to change each frame
      buf = (frames.last - target_frame) / num_frames.to_f

      num_frames.times do |i|
        if i == (num_frames-1) then add_frame(target_frame.copy) # last iteration, last frame... we can cheat.
        else add_frame(create_frame + buf) # create_frame clones the last frame, and buf moves it closer to target
        end
      end

      self
    end

    # Chops the specified amount of time off of the end of this animation and then returns self.
    def truncate_time(seconds)
      raise "Can't calculate frames from seconds: frame_time is zero!" if frame_time == 0
      num_frames = (seconds / frame_time).to_i
      return self if num_frames == 0
      frames[-1..-num_frames].each { |i| frames.delete i }
      self
    end

    alias add_frames add_frame
  end
end
