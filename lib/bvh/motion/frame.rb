class Bvh
  class Motion

    class Frame
      # The array of ChannelData objects for this frame: one ChannelData instance for each bone.
      attr_reader :channel_data

      def initialize()
        @channel_data = []
      end

      # Creates a copy of this frame, including a dup of its channel data.
      def copy
        ret = self.class.new
        channel_data.each do |datum|
          ret.channel_data << datum.dup
        end
        ret
      end

      # call-seq:
      #   frame + frame  => new_frame
      #   frame - frame  => new_frame
      #   frame / frame  => new_frame
      #   frame * frame  => new_frame
      #   frame + number => new_frame
      #   frame - number => new_frame
      #   frame / number => new_frame
      #   frame * number => new_frame
      #
      # Performs arithmetic on this frame with the target. The second operand may be either a number or another Frame.
      # If the target is a number, then that number is added to, subtracted from, multiplied with, or divided against
      # each channel of each ChannelData object in this frame.
      #
      # If the target is another Frame, the arithmetic looks something like this (simplified):
      #   return_value.channel_data[0] = frame1.channel_data[0] * frame2.channel_data[0]
      #   return_value.channel_data[0] = frame1.channel_data[1] * frame2.channel_data[1]
      #   return_value.channel_data[0] = frame1.channel_data[2] * frame2.channel_data[2]
      #   . . .
      #
      # Both frames must contain the same number of ChannelData instances, and each instance must
      # have the same number of channels, and each instance must also reference the same bone.
      #
      # Returns a new frame containing the result.
      #
      def arithmetic_proc(target)
        # Fooled you! I metaprogrammed it to save some typing!
      end
      undef arithmetic_proc

      [:+, :-, :/, :*].each do |operator|
        define_method operator do |target|
          if target.kind_of?(Frame)
            unless channel_data.length == target.channel_data.length
              raise "Expected both frames to have the same amount of data"
            end
            ret = Frame.new
            channel_data.each_with_index do |datum, index|
              ret.channel_data << datum.send(operator, target.channel_data[index])
            end
            ret
          else
            ret = Frame.new
            channel_data.each { |datum| ret.channel_data << datum.send(operator, target) }
          end
          ret
        end
      end

      # Returns the channel data for the specified bone.
      def channel_data_for(bone)
        @channel_data.each { |c| return c if c.bone == bone }
        raise "Channel data for bone not found: #{bone.name}"
      end

      # Returns the relative, or local, transform matrix for the specified bone in this frame.
      def relative_transform_matrix(bone)
        return channel_data_for(bone).relative_transform_matrix
      end

      # Returns the transform matrix of the root node multiplied with its children recursively
      # down to the specified bone, the result being the total transformation in worldspace for this frame.
      def absolute_transform_matrix(bone)
        relative = relative_transform_matrix(bone)
        if bone.parent then absolute_transform_matrix(bone.parent) * relative
        else relative
        end
      end

      # Modifies a single attribute of the channel data for this bone in this frame. Returns self.
      #
      # Ex:
      #   bvh.last_frame.set_channel bone, 'Xrotation', 180 # => sets the bone to a 180 deg rotation around the X-axis
      def set_channel(bone, channel, theta)
        channel_data_for(bone).set_channel(channel, theta)
      end

      # Retrives the value for a specific channel for a specific bone within this frame.
      def get_channel(bone, channel)
        channel_data_for(bone).get_channel(channel)
      end

      # Modifies the channel data for this bone in this frame, resulting in a rotation around the specified
      # channel.
      #
      # Ex:
      #   bvh.last_frame.set_channel bone, 'Xrotation', 180 # => rotates the bone by 180 deg rotation around the X-axis
      def rotate!(bone, channel, theta)
        set_channel(bone, channel, channel_data_for(bone).get_channel(channel) + theta)
      end

      # Adds x, y and z to the X, Y and Z position channels for this bone in this frame, resulting in a "movement" or
      # translation.
      def translate!(bone, x, y, z)
        set_channel(bone, 'Xposition', channel_data_for(bone).get_channel('Xposition')+x)
        set_channel(bone, 'Yposition', channel_data_for(bone).get_channel('Yposition')+y)
        set_channel(bone, 'Zposition', channel_data_for(bone).get_channel('Zposition')+z)
      end

      alias transform_matrix absolute_transform_matrix
      alias local_transform_matrix relative_transform_matrix
    end
  end
end
