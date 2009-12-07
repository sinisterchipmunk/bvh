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

      alias / find_by_name
    end
  end
end
