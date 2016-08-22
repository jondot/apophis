require 'open-uri'

module Apophis
  class AppiumRunner

    def doctor!
      errors = []
      errors << "No valid appium install, or not available to this environment." unless system('appium -v > /dev/null')
      errors << "No valid unix tooling: lsof" unless system('lsof -v > /dev/null 2>&1')

      raise errors.join("\n") unless errors.empty?
    end

    def any?
      appiums.size > 0
    end

    def available?(port)
      return false unless port
      !!find(port)
    end

    def kill_and_wait(port, timeout=10)
      DottyTimeout.timeout(timeout) do
        kill(port)
        !available?(port)
      end
    end

    def kill(port)
      app = find(port)
      return unless app
      Process.kill('KILL', app[:pid])
    end

    def find(port)
      appiums.find{|app| app[:url] =~ /:#{port}/}
    end

    def launch_and_wait(port=nil, timeout=20)
      port = port || find_available_port(4500)

      #we'll use the env variable later to locate this process (`ps -p <PID> -wwwE`)
      Process.spawn("APOPHIS_TAG=#{port} appium -p #{port} -bp #{port+1} > /dev/null 2>&1")
      DottyTimeout.timeout(timeout){ available?(port) }

      { port: port }
    end

    def probe(candidate)
      begin
        Timeout.timeout(0.5) do
          res = JSON.parse(open("#{ candidate }/status").read)
          !!res["value"]
        end
      rescue Exception => _
        false
      end
    end

    def find_available_port(above)
      Selenium::WebDriver::PortProber.above(above)
    end

    def appiums
      `lsof -P -n -i -sTCP:LISTEN`.lines.map(&:chomp) \
            .map{|ln| ln =~ /\D+\s(\d+)\s.*TCP\s+(.*):(\d+)\s+\(LISTEN\)/; { pid: $1.to_i, url: "http://#{$2}:#{$3}/wd/hub".sub('*', 'localhost')} }
            .select{|app| app[:pid] > 0}
            .select{|app| probe(app[:url])}
    end
  end
end

