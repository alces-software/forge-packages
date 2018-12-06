#!/bin/sh
yum install -y -e0 nfs-utils newt

cp -R data/* "${cw_ROOT}"
