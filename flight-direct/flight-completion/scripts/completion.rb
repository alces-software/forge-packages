#
# Ruby Script for rendering FlightDirect bash completions
#

require_relative "#{ENV['FL_ROOT']}/lib/flight_direct.rb"
require 'flight_direct/cli'

return unless Process.euid == 0

template = File.read(
  File.join(FlightDirect.root_dir, 'scripts/bash_completion.sh.erb')
)
context = FlightDirect::CLI.instance_eval { binding }
completion = ERB.new(template, nil, '-').result(context)
file = File.join(FlightDirect.root_dir, 'scripts/bash_completion.sh')
File.write(file, completion)

