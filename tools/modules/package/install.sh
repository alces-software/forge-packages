#!/bin/bash
require files
files_load_config distro

yum install -y -e0 tcl

cp -R data/* "${cw_ROOT}"

sed -i -e "s,_ROOT_,${cw_ROOT},g" "${cw_ROOT}/etc/modulerc/modulespath" \
  "${cw_ROOT}/etc/profile.d/09-modules.csh"
