require 'whirly'
require 'paint'

module Alces
  module Flight
    module Spinner
      class << self
        def run(status)
          Signal.trap("USR1") do
            Whirly.stop
            exit(0)
          end
          Signal.trap("INT") do
            Whirly.stop
            exit(0)
          end
          Whirly.start(spinner: 'star', remove_after_stop: true, append_newline: false, status: Paint[status, '#2794d8'])
	  sleep
        end
      end
    end
  end
end
