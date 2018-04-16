#!/bin/bash

cp -R data/* "${cw_ROOT}"

cat <<EOF > ${cw_ROOT}/etc/cluster-customizer.rc
################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
#cw_CLUSTER_CUSTOMIZER_bucket="s3://yourbucket"
#cw_CLUSTER_CUSTOMIZER_access_key_id=""
#cw_CLUSTER_CUSTOMIZER_secret_access_key=""
#cw_CLUSTER_CUSTOMIZER_region="eu-west-1"
#cw_CLUSTER_CUSTOMIZER_account_profiles="default"
#cw_CLUSTER_CUSTOMIZER_features=""
#cw_CLUSTER_CUSTOMIZER_feature_set=""
#cw_CLUSTER_CUSTOMIZER_path="${cw_ROOT}/var/lib/customizer"
#cw_CLUSTER_CUSTOMIZER_custom_paths="/opt/alces"
EOF

cat <<\EOF >> "${cw_ROOT}"/etc/meta.d/customizer.rc
: '
: SYNOPSIS: Customization handler configuration details
: '
################################################################################
##
## Alces Clusterware - Metadata file
## Copyright (c) 2016 Alces Software Ltd
##
################################################################################
require files
if files_load_config --optional cluster-customizer; then
  if files_load_config --optional instance-aws config/cluster; then
    default_bucket="s3://alces-flight-${cw_INSTANCE_aws_account_hash}"
  fi
  cw_META_customizer_s3path="${cw_CLUSTER_CUSTOMIZER_bucket:-${default_bucket}}/customizer"
  cw_META_customizer_s3path_desc="Customizer bucket prefix"
  unset default_bucket
fi
EOF

# Note: there is no check that the following initializer is only called once,
# as there is with many of the handlers. Therefore, it doesn't matter that we
# call it here; doing so supports both the use cases of preinstallation as part
# of a base image, and post-boot installation with immediate application of
# account profiles.
${cw_ROOT}/etc/handlers/forge-customizer-compat/initialize
