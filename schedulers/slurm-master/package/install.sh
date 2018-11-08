#!/bin/bash
require files
files_load_config distro

if [[ "$cw_DIST" == "el6" ]]; then
  echo "Slurm is not supported on EL6"
  exit 1
fi

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
    data/init/systemd/flight-slurm-slurmctld.service \
    > /etc/systemd/system/flight-slurm-slurmctld.service
cat <<EOF > /etc/tmpfiles.d/flight-slurm.conf
# Flight Slurm runtime directory
d /run/slurm 0755 slurm root -
EOF

systemctl enable flight-slurm-slurmctld.service

# Create needed system dirs owned by Slurm user.
slurm_system_dirs=(/var/{log,run,spool}/slurm)
slurm_user='slurm'
mkdir -p "${slurm_system_dirs[@]}"
touch /var/log/slurm/accounting
chown -R "${slurm_user}:${slurm_user}" "${slurm_system_dirs[@]}"
chmod 0644 /var/log/slurm/accounting
