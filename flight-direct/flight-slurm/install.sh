#!/bin/sh

yum install -y -e0 newt

cp -r data/libexec "${cw_ROOT}"

if [ "$FL_CONFIG_ROLE" == "login" ]; then
    flight forge install alces/slurm-master
else
    flight forge install alces/slurm-compute
fi
