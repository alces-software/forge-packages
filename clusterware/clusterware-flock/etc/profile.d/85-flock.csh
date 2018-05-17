################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2018 Stephen F. Norledge and Alces Software Ltd
##
################################################################################
setenv cw_ROOT "$cw_ROOT"
/bin/bash "$cw_ROOT"/etc/profile.d/85-flock.sh
unsetenv cw_ROOT
