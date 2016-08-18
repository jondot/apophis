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

      caps[:runner] ||= {}
      runner = caps[:runner]

      if runner && runner[:genymotion] && gm.devices.empty?
        @log.info '---> no android device found, launching genymotion...'
        gm.launch(runner[:genymotion])
        @log.info '---> devices available:'
        @log.info gm.devices.join("\n")
      end

      port = runner ? runner[:port] : nil
      ar = AppiumRunner.new
      ar.doctor!

      if ar.available?(port)
        @log.info "--> killing appium on port #{port}"
        ar.kill_and_wait(port)
      end

      @log.info '---> launching a new appium...'
      launchinfo = ar.launch_and_wait
      # this is the magic: map the fresh appium port to this current test
      caps[:appium_lib][:port] = launchinfo[:port]
      caps[:runner][:port] = launchinfo[:port]

      @log.info "---> done. wiring caps to appium #{launchinfo}"
      @log.info caps


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
    def cleanup(caps=nil)
      @log.info '---> cleaning up...'
      if caps
        port = caps[:runner][:port]
        ar = AppiumRunner.new

        if ar.available?(port)
          @log.info "--> killing appium on port #{port}"
          ar.kill_and_wait(port)
        end
      end

      $driver.driver_quit if $driver
      @log.info '---> done.'
    end
  end
end
