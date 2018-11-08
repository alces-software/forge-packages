#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" ]]; then
  echo "MUNGE is not supported on el6"
  exit 1
elif [[ "$cw_DIST" == "el7" ]]; then
  yum install -y openssl
elif [[ "$cw_DIST" == "ubuntu1604" ]]; then
  apt-get install -y openssl libssl1.0.0
fi

cp -R data/opt "${cw_ROOT}"

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
  data/init/systemd/flight-slurm-munged.service \
  > /etc/systemd/system/flight-slurm-munged.service

# munged is fussy about these permissions
chmod g-w "${cw_ROOT}" "${cw_ROOT}/opt/"

systemctl enable flight-slurm-munged.service

# Create MUNGE user and group.
getent group munge &>/dev/null || groupadd --gid 363 munge
getent passwd munge &>/dev/null || useradd --uid 363 --gid 363 \
  --shell /sbin/nologin --home-dir "${cw_ROOT}/opt/munge" munge

# MUNGE user needs to own this.
chown -R munge:munge "${cw_ROOT}/opt/munge/var"
chmod 0711 "${cw_ROOT}"/opt/munge/var/run/munge

# Create MUNGE key, required for authentication between nodes - must be the
# same on all nodes so create by hashing the cluster name.
munge_path="$(echo ~munge)"
munge_key_dir="${munge_path}/etc/munge"
munge_key="${munge_key_dir}/munge.key"
munge_user='munge'

if [ "${FL_CONFIG_CLUSTERNAME}" ]; then
  echo -n "${FL_CONFIG_CLUSTERNAME}" | sha512sum | cut -d' ' -f1 > "${munge_key}"
  chmod 400 "${munge_key}"
  chown -R "${munge_user}:${munge_user}" "${munge_key_dir}"
else
  echo "Unable to determine cluster name for MUNGE key generation, exiting."
  exit 1
fi
