################################################################################
##
## Alces Clusterware - Handler support functions
## Copyright (C) 2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
require files
require network
require ruby
require log

files_load_config --optional cluster-slurm || true

slurm_log() {
    local message
    message="$1"
    log "${message}" "${cw_CLUSTER_SLURM_log}"
}

slurm_log_blob() {
    log_blob "${cw_CLUSTER_SLURM_log}" "$@"
}

slurm_control_node_iptables_rule() {
    local compute_node_ip interface
    compute_node_ip="$1"
    interface="$(network_get_route_iface ${compute_node_ip})"

    # Master node should accept requests on all ports for communication back
    # from nodes' slurmstepd daemons. In future may want to specify
    # SrunPortRange but this is fine for now.
    echo "INPUT -i ${interface} -s ${compute_node_ip} -p tcp -j ACCEPT"
}

slurm_compute_node_iptables_rule() {
    local control_node_ip interface
    control_node_ip="$1"
    interface="$(network_get_route_iface ${control_node_ip})"

    # Compute nodes should accept requests from master node to their slurmd.
    echo "INPUT -i ${interface} -s ${control_node_ip} -p tcp --dport 6818 -j ACCEPT"
}
