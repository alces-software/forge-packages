#: SYNOPSIS: Manage the flight-cache server
#: ROOT: true

require 'flight_config'

desc 'snapshot ADDRESS', 'Preform a package snapshot'
long_desc <<-LONGDESC
LONGDESC
loki_command(:snapshot) do |address|
  # Set the `BASE_URL` of the snapshot
  ENV['ANVIL_BASE_URL'] = "http://#{address}"
  ENV['RAILS_ENV'] = 'snapshot'
  exec(<<~EOF
cd #{FlightDirect.root_dir}/opt/anvil && \
rake packages:snapshot && \
systemctl enable anvil
EOF
)
end

