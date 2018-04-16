################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2016 Stephen F. Norledge and Alces Software Ltd
##
################################################################################
setenv cw_ROOT "$cw_ROOT"
/bin/bash "$cw_ROOT"/etc/profile.d/10-clusterable.sh force
unsetenv cw_ROOT
