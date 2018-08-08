#!/bin/bash

package_name='flight-syncer'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"
mkdir -p "${temp_dir}/data"

pushd .. > /dev/null
rm -rf vendor
bundle install --standalone --path vendor/flight-syncer
popd > /dev/null

rm -rf ../vendor/flight-syncer/cache
cp -pr ../.bundle ../etc ../libexec ../lib ../vendor "${temp_dir}/data"

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
