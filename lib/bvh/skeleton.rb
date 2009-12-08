class Bvh
  class Skeleton
    attr_accessor :root

    def find_by_name(name); root.find_by_name(name); end

    alias / find_by_name

    class Bone
      # the name of this bone
      attr_accessor :name

      # this bone's parent bone, if any (if nil, this bone is a root)
      attr_reader :parent

      # the channels, or degrees of freedom, that this bone allows -- and the order that they appear in
      attr_reader :channels

      # the offset of this bone in relation to its parent
      attr_reader :offset

      # an array of joints, or child bones. Each should have its parent set to this bone. See also #add_joint!
      attr_reader :joints

      def initialize(name = nil, parent = nil)
        @name, @parent = name, parent
        @channels, @offset, @joints = [], [], []
        @frames = []
      end

      # Adds the specified bone to this bone's list of joints, setting its parent equal to this bone.
      # This bone is returned.
      def add_joint!(joint)
        joint.instance_variable_set("@parent", self)
        joints << joint unless joints.include? joint
        self
      end

      # returns true if this is a "leaf" node; that is, there are no joints
      def end_site?
        joints.length == 0
      end

      # returns the descendant joint (or self) with the specified name.
      def find_by_name(name)
        return self if self.name == name
        joints.each { |j| r = j.find_by_name(name); return r unless r.nil? }
        nil
      end

      # Returns the length of this bone, inferred from the offset of its first joint.
      def length
        if end_site? then 0
        else
          ofs = joints.first.offset
          # ofs is a vector, so we need its magnitude
          if ofs.nil? then 0
          else Math.sqrt(ofs[0]**2) + Math.sqrt(ofs[1]**2) + Math.sqrt(ofs[2]**2)
          end
        end
      end

      # Returns a unit vector representing the orientation of this bone, inferred from the offset of its first joint.
      def orientation
        if end_site? then [0,0,0]
        else
          ofs = joints.first.offset
          if ofs.nil? then [0,0,0]
          else
            # ofs is a vector, so we need to normalize it
            max = proc { |a,b| a.to_f.abs > b.to_f.abs ? a.to_f.abs : b.to_f.abs }
            max = max.call(ofs[0], max.call(ofs[1], ofs[2]))
            if max > 0 then [ofs[0].to_f / max, ofs[1].to_f / max, ofs[2].to_f / max]
            else [0,0,0]
            end
          end
        end
      end

      alias / find_by_name
    end
  end
end
