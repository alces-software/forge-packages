#!/bin/bash

cp -R data/* "${FL_ROOT}"
chmod u+x "${FL_ROOT}/etc/cron.reboot/syncer.sh"
