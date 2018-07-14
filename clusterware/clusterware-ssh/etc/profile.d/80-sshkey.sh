################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2015 Alces Software Ltd
##
################################################################################
if [ -x "${cw_ROOT}"/libexec/share/setup-sshkey ]; then
    flight bash "${cw_ROOT}"/libexec/share/setup-sshkey
fi
