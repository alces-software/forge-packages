#!/bin/bash

package_name='clusterware-benchware'

VERSION="2018.1.0"

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

git clone -b ${VERSION} https://github.com/alces-software/benchware "${temp_dir}/data"
cp -r ../.bundle "${temp_dir}/data"

pushd "${temp_dir}/data" > /dev/null
  rm -rf vendor
  bundle install --standalone --path vendor/clusterware-benchware
popd > /dev/null

pushd "${temp_dir}" > /dev/null
  zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
