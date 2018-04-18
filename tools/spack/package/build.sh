#!/bin/bash

package_name='spack'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

pushd "$temp_dir/data" > /dev/null

curl -L -o spack.tar.gz "https://github.com/spack/spack/releases/download/v0.11.2/spack-0.11.2.tar.gz"
mkdir -p opt/spack
cd opt/spack
tar --strip-components 1 -xvf "${temp_dir}"/data/spack.tar.gz
cd "$temp_dir/data"
rm spack.tar.gz

popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
