#!/bin/bash

# Allow errors during the intial db creation, this is required for
# reinstalls to work correctly
set +e

# Moves the directories in place
cp -r ./fl_root/* $FL_ROOT

# Creates the postgres user, the user creation is allowed to fail
user=postgres
adduser $user

# Initializes the database
opt_dir=$FL_ROOT/opt/postgres
bin_dir=$opt_dir/bin
var_dir=$FL_ROOT/var/postgres
log=$FL_ROOT/var/log/postgresql.log
mkdir $var_dir
touch $log
chown -R $user $var_dir $log
sudo -u $user $bin_dir/initdb -D $var_dir/data

# Do not allow errors after this point
set -e

# Writes the systemd config file
# Modified from:
# https://unix.stackexchange.com/questions/220362/systemd-postgresql-start-script
service=postgresql-flight
systemd=/etc/systemd/system/$service.service
cat << SYSTEMD > $systemd
[Unit]
Description=PostgreSQL database server
After=network.target

[Service]
Type=forking

User=$user
Group=$user

# Disable OOM kill on the postmaster
OOMScoreAdjust=-1000
# ... but allow it still to be effective for child processes
# (note that these settings are ignored by Postgres releases before 9.5)
Environment=PG_OOM_ADJUST_FILE=/proc/self/oom_score_adj
Environment=PG_OOM_ADJUST_VALUE=0

# Maximum number of seconds pg_ctl will wait for postgres to start.  Note that
# PGSTARTTIMEOUT should be less than TimeoutSec value.
Environment=PGSTARTTIMEOUT=270

Environment=LD_LIBRARY_PATH=$opt_dir/lib:$LD_LIBRARY_PATH
Environment=PGDATA=$var_dir/data
Environment=PGLOG=$log

ExecStart=$bin_dir/pg_ctl start -D \${PGDATA} -s -w -t \${PGSTARTTIMEOUT} -l \${PGLOG}
ExecStop=$bin_dir/pg_ctl stop -D \${PGDATA} -s -m fast -l \${PGLOG}
ExecReload=$bin_dir/pg_ctl reload -D \${PGDATA} -s -l \${PGLOG}

# Give a reasonable amount of time for the server to start up/shut down.
# Ideally, the timeout for starting PostgreSQL server should be handled more
# nicely by pg_ctl in ExecStart, so keep its timeout smaller than this value.
TimeoutSec=300

[Install]
WantedBy=multi-user.target
SYSTEMD

# Reloads the systemd daemon and starts postgres
systemctl daemon-reload
systemctl enable $service
systemctl start $service

