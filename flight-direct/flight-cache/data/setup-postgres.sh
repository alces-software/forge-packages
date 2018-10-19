#!/bin/bash
set -e

# Installs the required packages
yum install wget -y

# Extracts the compiled version of postgres
bash ./extract-postgres.sh

# Creates the postgres user
user=postgres
adduser $user

# Initializes the database
var_dir=/var/postgres
log=/var/log/postgresql.log
mkdir $var_dir
touch $log
chown -R $user $var_dir $log
sudo -u $user initdb -D $var_dir/data

# Writes the systemd config file
# Modified from:
# https://unix.stackexchange.com/questions/220362/systemd-postgresql-start-script
systemd=/usr/lib/systemd/system/postgresql.service
cat << SYSTEMD >> $systemd
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

Environment=PGDATA=$var_dir/data
Environment=PGLOG=$log

ExecStart=/usr/bin/pg_ctl start -D \${PGDATA} -s -w -t \${PGSTARTTIMEOUT} -l \${PGLOG}
ExecStop=/usr/bin/pg_ctl stop -D \${PGDATA} -s -m fast -l \${PGLOG}
ExecReload=/usr/bin/pg_ctl reload -D \${PGDATA} -s -l \${PGLOG}

# Give a reasonable amount of time for the server to start up/shut down.
# Ideally, the timeout for starting PostgreSQL server should be handled more
# nicely by pg_ctl in ExecStart, so keep its timeout smaller than this value.
TimeoutSec=300

[Install]
WantedBy=multi-user.target
SYSTEMD

# Reloads the systemd daemon and starts postgres
systemctl daemon-reload
systemctl enable postgresql
systemctl start postgresql

