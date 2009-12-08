class Bvh
  class Motion
    class ChannelData < Hash
      # The bone that is related to this channel data.
      attr_reader :bone

      def initialize(bone, *args, &block)
        @bone = bone
        super(*args, &block)
      end

      [:+, :-, :/, :*].each do |operator|
        define_method operator do |target|
          ret = ChannelData.new(bone)
          if target.kind_of?(ChannelData)
            target.each { |key, value| ret[key] = 0.send(operator, value) }
            self.each do |key, value|
              ret[key] = value.send(operator, 0)
              ret[key] = value.send(operator, target[key]) if target.key?(key)
            end
          else
            self.each { |key, value| ret[key] = value.send(operator, target) }
          end
          ret
        end
      end

      # Sets the specified channel to a value of theta, and then returns self.
      def set_channel(channel, theta)
        channel = channel.to_s if channel.kind_of? Symbol
        raise "Channel not found (expected one of #{self.keys.inspect})" unless self.keys.include? channel
        self[channel] = theta
      end

      # Modifies this datum, resulting in a rotation around the specified channel.
      def rotate!(channel, theta)
        set_channel(channel, theta)
      end

      # Sets the X, Y and Z position channels of this datum to the supplied x, y, z values.
      def translate!(x, y, z)
        set_channel('Xposition', x)
        set_channel('Yposition', y)
        set_channel('Zposition', z)
      end

      # Returns the transform matrix for this bone's channel data. See also
      # Bvh::Motion::Frame#relative_transform_matrix(bone) and Bvh::Motion::Frame#absolute_transform_matrix(bone)
      #
      # The resultant matrix needs to be multiplied against the parent bone's transform matrix in order
      # to be accurate to worldspace. Otherwise it's only accurate in local space.
      def relative_transform_matrix()
        # theta is retrieved from the set of numbers loaded from the BVH file, or is supplied directly
        #
        # R is the matrix calculated for a rotation of theta degrees around the vector V
        #    This is performed on right, view and up vectors, multiplying the three matrices together
        #    to construct the rotation matrix for this bone. Since the calculations are done in world
        #    space, the right, up and view vectors are [1,0,0]; [0,1,0]; [0,0,1], respectively. No reason
        #    we couldn't attach a Camera object to this bone and figure it out that way, but it'd actually
        #    be more work to create and maintain the camera than to just calculate the matrix. Obviously,
        #    the resultant matrix needs to be multiplied against the parent bone's rotation matrix in order
        #    to be accurate to worldspace. Otherwise it's only accurate in local space.
        #
        # R = [tx^2 + c,  txy - sz,  txz + sy,  0]
        #     [txy + sz,  ty^2 + c,  tyz - sx,  0]
        #     [txz - sy,  tyz + sx,  tz^2 + c,  0]
        #     [       0,         0,         0,  1]
        #
        # where c = cos theta,
        #       s = sin theta,
        #       t = 1 - c
        # [x,y,z] = a unit vector on the axis of rotation

        # bone.channels.each so that we don't lose order of operation
        r = Matrix.identity(4)
        bone.channels.each do |chan|
          v = nil
          case chan.downcase
            when 'xrotation' then v = [1,0,0] # right vector
            when 'yrotation' then v = [0,1,0] # up vector
            when 'zrotation' then v = [0,0,1] # view vector
            else next # ignore nonrotational values. To my knowledge, this includes only position values.
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

        # Finally, the last row is simply set to the translation and/or bone offset.
        r[0,3] = bone.offset[0] + (self.key?("Xposition") ? self['Xposition'] : 0)
        r[1,3] = bone.offset[1] + (self.key?("Yposition") ? self['Yposition'] : 0)
        r[2,3] = bone.offset[2] + (self.key?("Zposition") ? self['Zposition'] : 0)
        r
      end

      alias local_transform_matrix relative_transform_matrix
    end
  end
end
