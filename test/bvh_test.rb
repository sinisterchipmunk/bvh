require 'helper'
require 'bvh'

class BvhTest < Test::Unit::TestCase
  context "The Bvh class" do
    should "import BVH files" do
      Bvh.import("test_data/chinese.bvh")
      Bvh.import("test_data/lady.bvh")
    end
  end

  context "A Bvh instance" do
    setup do
      @chinese = Bvh.import("test_data/chinese.bvh")
      @lady = Bvh.import("test_data/lady.bvh")
    end

    should "export to file" do
      @chinese.export("test_output/chinese.bvh")
      @lady.export("test_output/lady.bvh")
    end

    should "be able to import its own exports" do
      Bvh.import("test_output/chinese.bvh")
      Bvh.import("test_output/lady.bvh")
    end

    should "be able to calculate the rotation matrices" do
      frames = @chinese.motion.frames
      bone = @chinese.skeleton/"LeftWrist"
      
      puts frames.first.relative_rotation_matrix(bone).inspect
      puts frames.first.absolute_rotation_matrix(bone).inspect
    end
  end
end
