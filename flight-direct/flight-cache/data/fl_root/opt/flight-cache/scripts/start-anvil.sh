#!/bin/bash
source /etc/profile.d/flight-direct.sh
source $FL_ROOT/etc/runtime.sh
cd $FL_ROOT/opt/anvil
bundle exec rails server -p 80 -b 0.0.0.0 -e snapshot
