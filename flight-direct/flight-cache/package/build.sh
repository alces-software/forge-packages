#!/bin/bash

set -e

package_name='flight-cache'
anvil_tag='0.2.0'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"
cp -r ../data/* "${temp_dir}"

# Installs anvil including gems
pushd "${temp_dir}/fl_root/opt" > /dev/null
git clone https://github.com/alces-software/anvil.git
cd anvil
git checkout $anvil_tag
bundle install --path vendor/bundle --without development --with snapshot
pushd > /dev/null

# Installs the flight-cache gems
pushd "${temp_dir}/fl_root/opt/flight-cache" > /dev/null
bundle install --path vendor/bundle
popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
