#!/bin/bash

cp -R data/* "${cw_ROOT}"

if [ ! -f "${cw_ROOT}"/etc/cluster-firewall.rc ]; then
  cat <<EOF >> "${cw_ROOT}"/etc/cluster-firewall.rc
################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
# Uncomment the line below to entirely disable Clusterware firewall rules
#cw_CLUSTER_FIREWALL_disabled=true
EOF
fi

mkdir -p "${cw_ROOT}"/etc/cluster-firewall/static.d
cat <<\EOF > "${cw_ROOT}"/etc/cluster-firewall/static.d/gateway.rc
################################################################################
##
## Alces Clusterware - Firewall rules
## Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
if [ "$cw_INSTANCE_role" == "master" ]; then
  require network
  if network_is_ec2; then
    cluster_network=$(network_get_ec2_vpc_cidr_block)
  else
    require files
    files_load_config config config/cluster
    cluster_network="$(network_get_iface_network ${cw_CLUSTER_iface:-$(network_get_first_iface)})"
  fi
  cw_CLUSTER_FIREWALL_rules="gateway_in gateway_out gateway_masq"
  cw_CLUSTER_FIREWALL_rule_gateway_in="FORWARD -s ${cluster_network} -j ACCEPT"
  cw_CLUSTER_FIREWALL_rule_gateway_out="FORWARD -d ${cluster_network} -j ACCEPT"
  cw_CLUSTER_FIREWALL_rule_gateway_masq="POSTROUTING -t nat -s ${cluster_network} -j MASQUERADE"
  sysctl net.ipv4.ip_forward=1
  unset cluster_network
fi
EOF

mkdir -p "${cw_ROOT}"/etc/cluster-firewall/members.d
cat <<\EOF > "${cw_ROOT}"/etc/cluster-firewall/members.d/base.rc
################################################################################
##
## Alces Clusterware - Firewall rules
## Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
cw_CLUSTER_FIREWALL_rules="prv"
cw_CLUSTER_FIREWALL_rule_prv="INPUT -i $(network_get_route_iface ${cw_MEMBER_ip}) -s ${cw_MEMBER_ip} -j ACCEPT"
EOF

"${cw_ROOT}"/etc/handlers/cluster-firewall/configure
