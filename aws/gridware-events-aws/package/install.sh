#!/bin/bash

cp -R data/* "${cw_ROOT}"

require files
files_load_config gridware
for name in ${cw_GRIDWARE_default_depot:-local} ${cw_GRIDWARE_init_depots}; do
  depot="${cw_GRIDWARE_root:-/opt/gridware}/${name}"
  if ! grep -q "${depot}/\$cw_DIST/etc/modules" "${cw_ROOT}"/etc/modulerc/modulespath; then
    sed -e "/^#=Alces Gridware Depots/a ${depot}/\$cw_DIST/etc/modules" \
        -i "${cw_ROOT}"/etc/modulerc/modulespath
  fi
done

cat <<EOF > "${cw_ROOT}"/etc/gridware/region_map.yml
---
eu-west-1: eu-west-1
eu-west-2: eu-west-1
eu-central-1: eu-central-1
us-east-1: us-east-1
us-east-2: us-east-1
us-west-1: us-east-1
us-west-2: us-east-1
ap-northeast-1: ap-southeast-2
ap-northeast-1: ap-southeast-2
ap-southeast-1: ap-southeast-2
ap-southeast-2: ap-southeast-2
ap-south-1: ap-southeast-2
sa-east-1: us-east-1
ca-central-1: us-east-1
EOF

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring Gridware configuration until next boot."
else
  "${cw_ROOT}"/etc/handlers/cluster-gridware/configure
fi
