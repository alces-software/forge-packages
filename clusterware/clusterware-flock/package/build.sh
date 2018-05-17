#!/bin/bash

package_name='clusterware-flock'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

mkdir -p "${temp_dir}"/data/opt/clusterware

cp -pR ../libexec "${temp_dir}"/data/opt/clusterware
cp -r ../etc "${temp_dir}"/data/opt/clusterware

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
