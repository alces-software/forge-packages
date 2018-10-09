#: SYNOPSIS: Manage the flight-cache server
#: ROOT: true

require 'flight_config'

desc 'snapshot ADDRESS', 'Preform a package snapshot'
long_desc <<-LONGDESC
LONGDESC
loki_command(:snapshot) do |address|
end
