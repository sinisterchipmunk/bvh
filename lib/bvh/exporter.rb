class Bvh
  class Exporter
    attr_reader :filename
    attr_reader :source

    def initialize(file)
      @filename = file
    end

    def export(bvh)
      #raise "File exists" if File.exist?(filename)
      unless bvh.frame_count == 0
        raise ArgumentError, "Frame time is 0; this would result in infinite FPS!" if bvh.frame_time == 0
        raise ArgumentError, "Frame time is #{bvh.frame_time}! Should be a positive number." if bvh.frame_time < 0
      end
      @bvh = bvh
      File.open(filename, "w+") do |file|
        @file = file
        file.puts "HIERARCHY"
        bvh.skeletons.each { |skel| export_skeleton(skel) }
        export_motion(bvh.motion)
        file.puts # end with a blank line
      end
    end

    private
    attr_reader :bvh, :file

    # export HIERARCHY data
    def export_skeleton(skele)
      export_root skele.root
    end

    # export ROOT node and its joints
    def export_root(root)
      file.puts "ROOT #{root.name}"
      file.puts "{"
      export_bone_data(root)
      file.puts "}"
    end

    # export JOINT node, or End Site if joint has no joints
    # level defines number of preceding tab stops
    def export_joint(bone, level = 1)
      tabs = "\t"*level
      header = if bone.end_site? then "End Site"
      else "JOINT #{bone.name}" 
      end
      file.puts "#{tabs}#{header}"
      file.puts "#{tabs}{"
      export_bone_data(bone, level)
      file.puts "#{tabs}}"
    end

    # exports bone data, regardless of type, including its joints
    # level defines number of preceding tab stops
    def export_bone_data(bone, level = 0)
      level += 1 # we're within a node, so it's one more tab than expected
      tabs = "\t"*level
      file.puts "#{tabs}OFFSET\t #{bone.offset.collect { |i| "%.6f" % i }.join("\t ")}"
      if bone.channels.length > 0
        chans = bone.channels.join(" ")
        file.puts("#{tabs}CHANNELS #{bone.channels.length} #{chans}")
      end
      bone.joints.each { |joint| export_joint(joint, level) }
    end

    # export MOTION data
    def export_motion(motion)
      file.puts "MOTION"
      file.puts "Frames: #{motion.frame_count}"
      file.puts "Frame Time: #{motion.frame_time}"
      motion.frames.each do |frame|
        line = ""
        # chan.bone.channels vs. chan.channels to maintain order
        frame.channel_data.each do |channel_data|
          channel_data.bone.channels.each do |i|
            chan = "%.6f" % channel_data[i]
            line = "#{line}#{chan}\t"
          end
        end
        file.puts line.strip
      end
    end
  end
end
