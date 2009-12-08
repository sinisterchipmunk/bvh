require 'helper'
require 'bvh'

### Since I don't really have much data to test against, this file mostly just tests that no
### errors are encountered.
###
### FIXME: Add assertion data.
###
class BvhTest < Test::Unit::TestCase
  context "The Bvh class" do
    should "import BVH files" do
      Bvh.import("test/data/in/karate.bvh")
    end
  end

  context "A Bvh instance" do
    setup do
      @karate = Bvh.import("test/data/in/karate.bvh")
    end

    should "export to file" do
      @karate.export("test/data/out/karate.bvh")
    end

    should "be able to import its own exports" do
      Bvh.import("test/data/out/karate.bvh")
    end

    should "be able to calculate the transform matrices" do
      frames = @karate.motion.frames
      bone = @karate.skeleton/"LeftWrist"

      # FIXME: i don't know what values to assert against
      frames.last.local_transform_matrix(bone)
      frames.last.transform_matrix(bone)
    end

    should "be able to add time to frames" do
      # add 3 seconds, during which each bone's offset should move and rotate by 3 units
      # no idea what this would look like if rendered, it's just a test
      frame_count = @karate.frame_count
      @karate.motion.add_time(3, @karate.motion.frames.last + 3)
      assert_equal frame_count+90, @karate.frame_count # 30 fps for 3 sec
    end
  end
end
