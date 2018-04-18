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

curl -L -o "${temp_dir}/src/vsc-base-2.5.8.tar.gz" https://files.pythonhosted.org/packages/f7/66/1ff7ecc4a93ba37e063f5bfbe395e95a547b1dec73b017c2724f4475a958/vsc-base-2.5.8.tar.gz
curl -L -o "${temp_dir}/src/vsc-install-0.10.32.tar.gz" https://files.pythonhosted.org/packages/5d/ca/1c41be2964be1355e15b4a88c7eef11c13c621220e27b69b2686c23cace2/vsc-install-0.10.32.tar.gz
curl -L -o "${temp_dir}/src/easybuild-framework-3.5.3.tar.gz" https://files.pythonhosted.org/packages/6f/a2/0c364993ee5264415e2b46af6323bbdcab610d36ceaca39c253c69cf40a1/easybuild-framework-3.5.3.tar.gz
curl -L -o "${temp_dir}/src/easybuild-easyblocks-3.5.3.tar.gz" https://files.pythonhosted.org/packages/3f/9a/cd137add36144a67368c8b472ec91b3475f95cbaf89442a394a5fe77dc53/easybuild-easyblocks-3.5.3.tar.gz
curl -L -o "${temp_dir}/src/easybuild-easyconfigs-3.5.3.tar.gz" https://files.pythonhosted.org/packages/86/c2/b6ddd15854148d6b2396f402526c64ea017041035e854cafd62f8b5c6a60/easybuild-easyconfigs-3.5.3.tar.gz
curl -L -o "${temp_dir}/src/bootstrap_eb.py" https://github.com/easybuilders/easybuild-framework/raw/master/easybuild/scripts/bootstrap_eb.py

export EASYBUILD_BOOTSTRAP_SOURCEPATH="${temp_dir}/src"
PATH="/opt/clusterware/opt/modules/bin:$PATH"
mkdir /opt/clusterware/opt/easybuild
chown alces /opt/clusterware/opt/easybuild
chmod 755 ${temp_dir}
sudo -E PYTHONDONTWRITEBYTECODE=true -E PATH=$PATH -u alces python ${temp_dir}/src/bootstrap_eb.py /opt/clusterware/opt/easybuild

mkdir opt
mv /opt/clusterware/opt/easybuild opt
chown -R root:root opt/easybuild

rm -rf "${temp_dir}"/src

popd > /dev/null

pushd "${temp_dir}" > /dev/null
zip -r ${package_name}.zip *
popd > /dev/null

mv "${temp_dir}"/${package_name}.zip .

rm -rf "${temp_dir}"
