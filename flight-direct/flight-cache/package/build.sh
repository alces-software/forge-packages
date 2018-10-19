#!/bin/bash

set -e

package_name='flight-cache'
anvil_tag='0.2.0'

yum install -y -e0 postgresql-devel wget

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"
cp -r ../data/* "${temp_dir}"

# Installs anvil and package the gems
# Due to the native ruby extensions, nokogiri et al needs to be compiled when
# the package is installed. Instead the gems are packaged into `vendor/cache`
# This means the gems can be installed without connecting to rubygems
pushd "${temp_dir}/fl_root/opt" > /dev/null
git clone https://github.com/alces-software/anvil.git
cd anvil
git checkout $anvil_tag
bundle package
pushd > /dev/null

# Installs the flight-cache gems
pushd "${temp_dir}/fl_root/opt/flight-cache" > /dev/null
bundle install --path vendor/bundle
popd > /dev/null

# Pulls in the compiled version of postgres
pushd $temp_dir > /dev/null
#
# The commented code was used to create the tarball, It is being kept as a
# future reference
#
# Fetches the postgres source code
# postgres='postgresql-9.6.9'
# wget https://ftp.postgresql.org/pub/source/v9.6.9/$postgres.tar.gz
# tar -xzf $postgres.tar.gz
# cd $postgres
#
# Configures and installs postgres
# ./configure --prefix=/usr
# make world -j $(nproc)
# make install-world -j $(nproc)
#
wget https://s3-eu-west-1.amazonaws.com/flight-direct/extract-postgres.sh
popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
