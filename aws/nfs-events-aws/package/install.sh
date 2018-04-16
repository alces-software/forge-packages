#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" || "$cw_DIST" == "el7" ]]; then
  yum install -y -e0 nfs-utils
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y nfs-kernel-server nfs-common
fi

cp -R data/* "${cw_ROOT}"

if [ ! -f "${cw_ROOT}"/etc/cluster-nfs.rc ]; then
    cat <<EOF >> "${cw_ROOT}"/etc/cluster-nfs.rc
cw_CLUSTER_NFS_exports="/home"
cw_CLUSTER_NFS_log="/var/log/clusterware/cluster-nfs.log"
EOF
fi

mkdir -p "${cw_ROOT}"/etc/cluster-nfs.d

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring NFS configuration until next boot."
else
  ${cw_ROOT}/etc/handlers/10-cluster-nfs/configure
fi
