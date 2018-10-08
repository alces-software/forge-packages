#!/bin/bash

scripts_dir=$FL_ROOT/opt/anvil/scripts

# Installs the required packages
yum -y -e0 install gcc

# Installs postgres if it is missing
if ! which postgres 2>&1 >/dev/null; then
  ./setup-postgres.sh
fi

# Ensures the profile has been sourced
source ~/.bashrc

# Sets the rails environment to be snapshot
if ! [[ -z "RAILS_ENV" ]]; then
  echo "export RAILS_ENV=snapshot" >> ~/.bashrc
  source ~/.bashrc
fi

# Installs the gems
cd $scripts_dir/..
bundle install --without development --with default snapshot

# Sets up systemd integration for anvil
systemd=/usr/lib/systemd/system/anvil.service
cat << SYSTEMD > $systemd
[Unit]
Description=Runs the anvil cache server
Requires=network.target
Requires=postgresql.service
[Service]
Type=simple
ExecStart=/bin/bash $scripts_dir/start-anvil.sh
TimeoutSec=30
[Install]
WantedBy=multi-user.target
SYSTEMD

# Applies the systemd change
systemctl daemon-reload
