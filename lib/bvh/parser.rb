class Bvh
  class Parser
    attr_reader :filename
    attr_reader :source

    def initialize(file)
      @filename = file
      @source = File.read(file)
    end

    def parse(bvh)
      @bvh = bvh

      # a little touch-up...
      s = source
      # it's tempting to just downcase the whole string, but that'd change the case of object names, which might be
      # bad for the end user. So we'll swap out specific keywords instead.
      s.gsub!(/^((\s*)(root|offset|channels|joint|end site|hierarchy)([^\n]*\n))/mi) do
        match = $~
        "#{match[2]}#{match[3].downcase.gsub(/\s/, '_')} \"#{match[4].strip}\"\n"
      end
      # make { . . . } into proper Ruby blocks
      s.gsub!(/\n\s*\{/m, ' do').gsub!(/\}/m, 'end')

      # Finally, handle the MOTION segment, which can be treated as a single method call.
      s.gsub!(/^((\s*)(motion)(.*))/mi) do
        "#{$~[2]}#{$~[3].downcase} <<-EOF\n#{$~[4].strip}\nEOF\n"
      end

      eval(s, binding, @filename, 1)
    end

    private
    attr_reader :bvh, :mode, :current_node

    def bone(type, name, &block)
      raise ArgumentError, "#{type} #{name} is unexpected at this time" unless mode == :hierarchy
      bone = type.new(name)

      if current_node.nil?
        bvh.create_skeleton!.root = bone
      else
        current_node.add_joint!(bone)
      end
      
      @current_node, bone = bone, @current_node
      instance_eval(&block)
      @current_node = bone
    end

    # Ex:
    #   root "joint-pelvis" do
    #     offset "0.00  0.00  0.00"
    #     channels "6 Xposition Ypoisition Zposition Zrotation Xrotation Yrotation"
    #     joint "joint-spine3" do
    #       . . .
    #     end
    #   end
    def root(name, &block)
      @current_node = nil
      bone Bvh::Skeleton::Bone, name, &block
    end

    # Ex:
    #   root "joint-pelvis" do
    #     . . .
    #     joint "joint-spine3" do
    #       offset "0.00  -10.65  0.00"
    #       channels "3 Zrotation Xrotation Yrotation"
    #       end_site do
    #         . . .
    #       end
    #     end
    #   end
    def joint(name, &block)
      bone Bvh::Skeleton::Bone, name, &block
    end

    # Ex:
    #   root "joint-pelvis" do
    #     . . .
    #     joint "joint-spine3" do
    #       . . .
    #       end_site do
    #         offset "0.00  -7.00  0.00"
    #       end
    #     end
    #   end
    def end_site(*unused, &block)
      bone Bvh::Skeleton::Bone, nil, &block
    end

    def hierarchy(*unused)
      @mode = :hierarchy
    end

    def offset(val)
      raise ArgumentError, "OFFSET is unexpected at this time" unless current_node
      raise ArgumentError, "Already have OFFSET data for this node" unless current_node.offset.length == 0
      current_node.offset.concat val.split.collect { |i| i.to_f }
    end

    def channels(val)
      raise ArgumentError, "CHANNELS is unexpected at this time" unless current_node
      raise ArgumentError, "Already have CHANNELS data for this node" unless current_node.channels.length == 0
      vals = val.split
      count = vals.shift.to_i # how many?
      raise ArgumentError, "Expected #{count} channels, found #{vals.length}" if vals.length != count
      current_node.channels.concat vals
    end

    def motion(motion_data)
      raise ArgumentError, "Motion data is unexpected at this time" unless mode == :hierarchy
      @mode = :motion
      frame_count = nil
      motion_data.each_line do |line|
        line = line.downcase.strip
        words = line.split
        case words.first
          when 'frames:'
            if words[1] =~ /[^0-9]/
              raise ArgumentError, "Only one positive numeric integer value expected at this time (not #{words[1]})"
            end
            frame_count = words[1].to_i
          when 'frame'
            case words[1]
              when 'time:'
                if words[2] =~ /[^0-9\.]/
                  raise ArgumentError, "Only one positive numeric decimal value expected at this time (not #{words[2]})"
                end
                bvh.frame_time = words[2].to_f
              else
                raise ArgumentError, "Motion data not understood: #{line}"
            end
          when nil, '' # blank line, do nothing
          else
            channels = words.collect do |w|
              raise ArgumentError, "Only numeric values are expected at this time (not #{w})" if w =~ /[^0-9\.\-]/
              w.to_f
            end
            add_frame(channels)
        end
      end
      unless frame_count == bvh.frame_count
        raise ArgumentError, "Expected %s frames, found %s" % [frame_count, bvh.frame_count]
      end
      unless frame_count == 0
        raise ArgumentError, "Frame time is 0; this would result in infinite FPS!" if bvh.frame_time == 0
        raise ArgumentError, "Frame time is #{bvh.frame_time}! Should be a positive number." if bvh.frame_time < 0
      end
    end

    def add_frame(channels)
      frame = Bvh::Motion::Frame.new
      frame.channel_data.concat channel_data(channels, bvh.root)
      bvh.frames << frame
      raise ArgumentError, "Not enough channels: Need #{-channels.length} more" if channels.length < 0
      raise ArgumentError, "Too many channels: #{channels.length} unaccounted for" if channels.length > 0
    end

    # this is now a binding.
#    def channel_data(channels, bone)
#      return [] unless bone.respond_to? :channels
#      data = Bvh::Motion::ChannelData.new(bone)
#      bone.channels.each do |channel|
#        data[channel] = channels.shift
#      end
#      r = [ data ]
#      if bone.respond_to? :joints
#        bone.joints.each do |child|
#          r.concat channel_data(channels, child)
#        end
#      end
#      r
#    end
  end
end
