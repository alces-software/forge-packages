#!/bin/bash

package_name='easybuild'

if [ -f ./${package_name}.zip ]; then
  echo "Replacing existing ${package_name}.zip in this directory"
  rm ./${package_name}.zip
fi

temp_dir=$(mktemp -d /tmp/${package_name}-build-XXXXX)

cp -r * "${temp_dir}"

pushd "$temp_dir/data" > /dev/null
mkdir "${temp_dir}/src"

curl -L -o "${temp_dir}/src/vsc-base-2.8.3.tar.gz" https://files.pythonhosted.org/packages/62/e5/589612e47255627e4752d99018ae7cff8f49ab0fa6b4ba7b2226a76a05d3/vsc-base-2.8.3.tar.gz
curl -L -o "${temp_dir}/src/vsc-install-0.11.2.tar.gz" https://files.pythonhosted.org/packages/b6/03/becd813f5c4e8890254c79db8d2558b658f5a3ab52157bc0c077c6c9beea/vsc-install-0.11.2.tar.gz
curl -L -o "${temp_dir}/src/easybuild-framework-3.7.1.tar.gz" https://files.pythonhosted.org/packages/d0/f1/a3c897ab19ad36a9a259adc0b31e383a8d322942eda1e59eb4fedee27d09/easybuild-framework-3.7.1.tar.gz
curl -L -o "${temp_dir}/src/easybuild-easyblocks-3.7.1.tar.gz" https://files.pythonhosted.org/packages/50/ea/3381a6e85f9a9beee311bed81a03c4900dd11c2a25c1e952b76e9a73486b/easybuild-easyblocks-3.7.1.tar.gz
curl -L -o "${temp_dir}/src/easybuild-easyconfigs-3.7.1.tar.gz" https://files.pythonhosted.org/packages/73/63/b22ff96b8c3e09e04466951c0c3aa7b2230a522792dd3ae37c5fce4c68ea/easybuild-easyconfigs-3.7.1.tar.gz
curl -L -o "${temp_dir}/src/bootstrap_eb.py" https://github.com/easybuilders/easybuild-framework/raw/master/easybuild/scripts/bootstrap_eb.py

export EASYBUILD_BOOTSTRAP_SOURCEPATH="${temp_dir}/src"
PATH="/opt/flight-direct/opt/modules/bin:$PATH"
mkdir /opt/flight-direct/opt/easybuild
chown centos /opt/flight-direct/opt/easybuild
chmod 755 ${temp_dir}
sudo -E PYTHONDONTWRITEBYTECODE=true -E PATH=$PATH -u centos python ${temp_dir}/src/bootstrap_eb.py /opt/flight-direct/opt/easybuild

mkdir opt
mv /opt/flight-direct/opt/easybuild opt
chown -R root:root opt/easybuild

rm -rf "${temp_dir}"/src

popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
