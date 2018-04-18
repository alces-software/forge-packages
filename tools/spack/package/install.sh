#!/bin/bash

cp -pR data/* "${cw_ROOT}"
if [ ! -d /opt/spack ]; then
    spack_arch=$("${cw_ROOT}"/opt/spack/bin/spack python -c 'print(spack.architecture.sys_type())')
    mkdir -p /opt/spack/etc
    mv "${cw_ROOT}"/opt/spack/{var,opt} /opt/spack
    mv "${cw_ROOT}"/opt/spack/share/{dotkit,modules,lmod} /opt/spack/etc
    mkdir -p /opt/spack/etc/{dotkit,modules,lmod}
    mkdir /opt/spack/etc/modules/${spack_arch}
else
    rm -rf "${cw_ROOT}"/opt/spack/{var,opt} "${cw_ROOT}"/opt/spack/share/spack/{dotkit,modules,lmod}
fi
ln -s /opt/spack/var "${cw_ROOT}"/opt/spack/var
ln -s /opt/spack/opt "${cw_ROOT}"/opt/spack/opt
ln -s /opt/spack/etc/dotkit "${cw_ROOT}"/opt/spack/share/spack/dotkit
ln -s /opt/spack/etc/modules "${cw_ROOT}"/opt/spack/share/spack/modules
ln -s /opt/spack/etc/lmod "${cw_ROOT}"/opt/spack/share/spack/lmod

if [ ! -d "${cw_ROOT}/etc/config/cluster" ]; then
  echo "Cluster not yet configured. Deferring Spack configuration until next boot."
else
  "${cw_ROOT}"/etc/handlers/configure-spack/configure
fi
