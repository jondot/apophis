
module Apophis
  class GenymotionRunner
    ADB = '$ANDROID_HOME/platform-tools/adb'.freeze
    GM = '/Applications/Genymotion.app/Contents/MacOS/player.app/Contents/MacOS/player'.freeze
    LAUNCH_WAIT = 5
    SPLASH_SLEEP = 5


    def initialize(gmroot=nil)
      @gm = gmroot || GM
    end

    def doctor!
      errors = []
      errors << "No valid Android tooling installed / or ANDROID_HOME not set: adb" unless system("#{ADB} version > /dev/null")
      errors << "Cannot find genymotion at #{@gm}" unless system("ls #{@gm} > /dev/null")

      raise errors.join("\n") unless errors.empty?
    end

    def devices
      out = `#{ADB} devices`
      out.lines.map(&:chop).reject{|line|line.start_with?('*')}.reject(&:empty?)[1..-1]
    end

    def launch(name, timeout=180)
      DottyTimeout.timeout(timeout) do
        Process.spawn("#{@gm} --vm-name '#{name}' > /dev/null 2>&1", out:'/dev/null', err:'/dev/null')

        begin 
          wait_for_android_device(LAUNCH_WAIT)
          return true
        rescue 
        end
        false
      end
      sleep(SPLASH_SLEEP)
    end

    def wait_for_android_device(timeout=5) #later, add an id for specific device
      DottyTimeout.timeout(timeout) do
        devices.size > 0
      end
    end
  end
end
