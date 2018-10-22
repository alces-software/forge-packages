#!/bin/bash

# Installs the required dependencies
yum install -y -e0 gcc

# Moves the directories in place
cp -r ./fl_root/* $FL_ROOT

# Install the anvil gems
cd $FL_ROOT/opt/anvil
bundle config build.pg --with-pg-config=$FL_ROOT/opt/postgres/bin/pg_config
bundle install --local --with snapshot default --without development

# Sets up systemd integration for anvil
systemd=/etc/systemd/system/flight-cache.service
cat << SYSTEMD > $systemd
[Unit]
Description=Runs the anvil cache server
Requires=network.target
Requires=postgresql-flight.service
[Service]
Type=simple
ExecStart=/bin/bash $FL_ROOT/opt/flight-cache/scripts/start-anvil.sh
TimeoutSec=30
[Install]
WantedBy=multi-user.target
SYSTEMD

# Applies the systemd change
systemctl daemon-reload

# Sets the node to build off its local cache
# This means all future packages will be installed from the cache
echo "FL_CONFIG_CACHE_URL=http://localhost" >> $FL_ROOT/var/flight.conf

