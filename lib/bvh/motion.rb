class Bvh
  class Motion
    attr_accessor :frame_time
    attr_reader :frames

    def initialize
      @frames = []
    end

    def frame_count
      frames.length
    end

    class Frame
      attr_accessor :channel_data
      attr_reader :skeletons

      def initialize(skeletons)
        @skeletons = skeletons
        @channel_data = []
      end

      def channel_data_for(bone)
        @channel_data.each { |c| return c if c.bone == bone }
        raise "Channel data for bone not found: #{bone.name}"
      end

      def relative_rotation_matrix(bone)
        return channel_data_for(bone).relative_rotation_matrix
      end

      # returns the rotation matrix of the root node multiplied with its children recursively
      # down to the specified bone, the result being the total rotation in worldspace.
      def absolute_rotation_matrix(bone)
        relative = relative_rotation_matrix(bone)
        if bone.parent then absolute_rotation_matrix(bone.parent) * relative
        else relative
        end
      end

      alias rotation absolute_rotation_matrix
    end

    class ChannelData < Hash
      attr_reader :bone

      def initialize(bone, *args, &block)
        @bone = bone
        super(*args, &block)
      end

      # returns the rotation matrix for this bone's channel data. See also
      # Bvh::Motion::Frame#relative_rotation_matrix(bone) and Bvh::Motion::Frame#absolute_rotation_matrix(bone)
      def relative_rotation_matrix
        # R = [tx^2 + c,  txy - sz,  txz + sy,  0]
        #     [txy + sz,  ty^2 + c,  tyz - sx,  0]
        #     [txz - sy,  tyz + sx,  tz^2 + c,  0]
        #     [       0,         0,         0,  1]
        #
        # where c = cos theta,
        #       s = sin theta,
        #       t = 1 - c
        # [x,y,z] = a unit vector on the axis of rotation

        # bone.channels to maintain order
        r = Matrix.identity(4)
        bone.channels.each do |chan|
          v = nil
          case chan.downcase
            when 'xrotation' then v = [1,0,0]
            when 'yrotation' then v = [0,1,0]
            when 'zrotation' then v = [0,0,1]
            else next
          end
          theta = self[chan]
          x, y, z = v
          c, s, t = Math.cos(theta), Math.sin(theta), 1 - Math.cos(theta)
          mat = Matrix.identity(4)
          mat[0,0], mat[0,1], mat[0,2] = t*(x**2) + c, t*x*y - s*z, t*x*z + s*y
          mat[1,0], mat[1,1], mat[1,2] = t*x*y + s*z, t*(y**2) + c, t*y*z - s*x
          mat[2,0], mat[2,1], mat[2,2] = t*x*z - s*y, t*y*z + s*x, t*(z**2) + c
          r *= mat
        end
        r
      end
    end
  end
end
