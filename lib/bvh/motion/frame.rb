class Bvh
  class Motion
    class Frame
      attr_accessor :channel_data

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
      #   bvh.last_frame.set_channel bone, 'Xrotation', 180 # => rotates the bone 180 degrees around the X axis
      def set_channel(bone, channel, theta)
        channel_data_for(bone).set_channel(channel, theta)
      end

      # Modifies the channel data for this bone in this frame, resulting in a rotation around the specified
      # channel.
      def rotate!(bone, channel, theta)
        set_channel(bone, channel, theta)
      end

      # Sets the X, Y and Z position channels for this bone in this frame.
      def translate!(bone, x, y, z)
        set_channel(bone, 'Xposition', x)
        set_channel(bone, 'Yposition', y)
        set_channel(bone, 'Zposition', z)
      end

      alias transform_matrix absolute_transform_matrix
      alias local_transform_matrix relative_transform_matrix
    end
  end
end
