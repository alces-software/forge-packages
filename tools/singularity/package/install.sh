#!/bin/bash

_install_singularity() {
    local checksum
    checksum="b05f2053b58fe15db06cfc5f3fa32fbd"

    cd /tmp
    wget https://github.com/singularityware/singularity/releases/download/$_VERSION/singularity-$_VERSION.tar.gz

    if [ "$checksum" != "$(md5sum singularity-$_VERSION.tar.gz |awk '{print $1}')" ] ; then
        echo "Sorry, the downloaded tarball has a mismatching checksum"
        exit 1
    fi

    tar xzf singularity-$_VERSION.tar.gz
    cd singularity-$_VERSION

    # install squashfs-tools for building images
    yum install -y -e0 squashfs-tools
    ./configure --prefix=/opt/apps/singularity/
    make
    make install
}

_install_modulefile() {
    mkdir -p /opt/apps/etc/modules/apps/singularity
    cp ${_RESOURCES_DIR}/modulefile "/opt/apps/etc/modules/apps/singularity/${_VERSION}"
}

_config_modulefile() {
    if ! grep -q /opt/apps/etc/modules /opt/clusterware/etc/modulerc/modulespath; then
	echo "/opt/apps/etc/modules" >> /opt/clusterware/etc/modulerc/modulespath
    fi
}

main() {
  if [ ! -d /opt/apps/singularity ]; then
      _install_singularity
      _install_modulefile
  fi
  _config_modulefile

  cat <<EOF
************************************

Installation complete. A modulefile has been installed for
using Singularity. To enable it run:

    alces module load apps/singularity/${_VERSION}

Once enabled you can then use Singularity by running:

    singularity --help

************************************

EOF
}

_VERSION="2.4"
_RESOURCES_DIR="$(pwd)/resources"

main "$@"
