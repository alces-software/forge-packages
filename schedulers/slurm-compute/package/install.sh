#!/bin/bash
require files
files_load_config distro

sed -e "s,_cw_ROOT_,${cw_ROOT},g" \
    data/init/systemd/flight-slurm-slurmd.service \
    > /etc/systemd/system/flight-slurm-slurmd.service
cat <<EOF > /etc/tmpfiles.d/flight-slurm.conf
# Flight Direct Slurm runtime directory
d /run/slurm 0755 slurm root -
EOF

systemctl enable flight-slurm-slurmd.service

# Create needed system dirs owned by Slurm user.
slurm_system_dirs=(/var/{log,run,spool}/slurm)
slurm_user='slurm'
mkdir -p "${slurm_system_dirs[@]}"
chown -R "${slurm_user}:${slurm_user}" "${slurm_system_dirs[@]}"
