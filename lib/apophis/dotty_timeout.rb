
module Apophis
  class DottyTimeout
    def self.timeout(timeout, &block)
      Timeout.timeout(timeout) do
        while(true)
          break if block.call
          sleep(2)
          putc '.'
        end
      end
      puts
    end
  end
end
