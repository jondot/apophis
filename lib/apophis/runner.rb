module Apophis
  class Runner
    def initialize(log=nil)
      @log = log
      unless log
        @log = Logger.new($stdout)
        @log.formatter = proc do |severity, datetime, progname, msg|
            date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
            "[#{date_format}] #{severity}: #{msg}\n"
        end
      end
    end

    def start(caps)
      @log.info "\n#{Apophis::BANNER}\n"
      gm = GenymotionRunner.new
      gm.doctor!

      if caps[:runner] && caps[:runner][:genymotion] && gm.devices.empty?
        @log.info '---> no android device found, launching genymotion...'
        gm.launch(caps[:runner][:genymotion])
        @log.info '---> devices available:'
        @log.info gm.devices.join("\n")
      end

      ar = AppiumRunner.new
      ar.doctor!

      appiums = ar.appiums
      @log.info "appiums: #{appiums}"
      if appiums.size > 0
        @log.info '---> being a douch and killing all running appiums.'
        @log.info '---> improve me later to map caps->device->device uuid->appium->appium session.'
        appiums.each do |app|
          @log.info "---> killing appium #{ app }"
          ar.kill_and_wait(app[:port])
        end
      end

      unless ar.any?
        @log.info '---> no appium found. launching...'
        launchinfo = ar.launch_and_wait
        caps[:appium_lib][:port] = launchinfo[:port]
        @log.info "---> done. wiring caps to appium #{launchinfo}"
      end


      @log.info "---> starting driver..."
      Appium::Driver.new(caps).start_driver
      Appium.promote_appium_methods Minitest::Spec
      @log.info "---> done"
    end

    #
    # note: Appium::Driver.new(..).start_driver is
    # sucky in that it populates $driver, which
    # #promote_appium_methods rely on. We'll have no
    # choice but chip-in on this nonsense when we
    # want to do cleanups etc.
    def cleanup
      @log.info '---> cleaning up...'
      $driver.driver_quit if $driver
      @log.info '---> done.'
    end
  end
end
