################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (C) 2015-2016 Stephen F. Norledge and Alces Software Ltd.
##
################################################################################
if [ "$PS1" ]; then
    _cw_set_prompt() {
        if [ -f "${cw_ROOT}"/etc/config/cluster/config.rc ]; then
            eval $(egrep '^cw_CLUSTER_(name|uuid)=' "${cw_ROOT}"/etc/config/cluster/config.rc)
            eval $(egrep '^cw_INSTANCE_role=' "${cw_ROOT}"/etc/config/cluster/instance.rc)
            eval $(egrep '^cw_INSTANCE_tag_CLUSTER_ROLES=' "${cw_ROOT}"/etc/config/cluster/instance.rc)
            cw_CLUSTER_name="${cw_CLUSTER_name:-${cw_CLUSTER_uuid}}"
            if [ "$cw_INSTANCE_role" == "master" ] || [[ "${cw_INSTANCE_tag_CLUSTER_ROLES}" == *":login:"* ]]; then
              PS1="[\u@\h\[\e[38;5;68m\](${cw_CLUSTER_name})\[\e[0m\] \W]\\$ "
            else
              PS1="[\u@\h\[\e[48;5;17;38;5;33m\](${cw_CLUSTER_name})\[\e[0m\] \W]\\$ "
            fi
            unset cw_CLUSTER_name cw_CLUSTER_uuid cw_INSTANCE_tag_CLUSTER_ROLES cw_INSTANCE_role
        else
            PS1="[\u@\h\[\e[1;33m\](unknown)\[\e[0m\] \W]\\$ "
        fi
    }
    eval $(grep '^cw_STATUS=' "${cw_ROOT}"/etc/clusterware.rc)
    if [ "${cw_STATUS}" != "ready" ]; then
        PS1="[\u@\h\[\e[1;31m\](unconfigured)\[\e[0m\] \W]\\$ "
        _cw_check_ready() {
            eval $(grep '^cw_STATUS=' "${cw_ROOT}"/etc/clusterware.rc)
            if [ "${cw_STATUS}" == "ready" ]; then
                cat <<EOF
$(echo -e "\e[1;33m")========
 NOTICE
========$(echo -e "\e[0m")
Configuration of this node is complete and it is now operational.

EOF
                _cw_set_prompt
                PROMPT_COMMAND="$(echo "${PROMPT_COMMAND}" | sed "s,; cw_ROOT=\"${cw_ROOT}\" _cw_check_ready,,g")"
                unset -f _cw_check_ready _cw_set_prompt
            fi
            unset cw_STATUS
        }
        PROMPT_COMMAND="${PROMPT_COMMAND:-:}; cw_ROOT=\"${cw_ROOT}\" _cw_check_ready"
    else
        _cw_set_prompt
        unset -f _cw_set_prompt
    fi
    unset cw_STATUS
fi
if [[ "$0" == '-'* || "$1" == "force" ]] || shopt -q login_shell; then
  IFS=: read -a xdg_config <<< "${XDG_CONFIG_HOME:-$HOME/.config}:${XDG_CONFIG_DIRS:-/etc/xdg}"
  for a in "${xdg_config[@]}"; do
    if [ -e "${a}"/clusterware/settings.rc ]; then
      source "${a}"/clusterware/settings.rc
      break
    fi
  done
  unset xdg_config a
  # Respect .hushlogin setting
  if [ ! -f "$HOME/.hushlogin" ]; then
    if [ -f "${cw_ROOT}"/etc/clusterware.rc ]; then
      eval $(egrep '^cw_(VERSION|STATUS)=' "${cw_ROOT}"/etc/clusterware.rc)
    fi
    if [ "${cw_SETTINGS_skip_status:-false}" == "false" ]; then
      if [ "${cw_STATUS}" == "unconfigured" ]; then
        cat <<EOF
$(echo -e "\e[1;33m")=============
 PLEASE NOTE
=============$(echo -e "\e[0m")
EOF
        if [[ "${cw_VERSION}" != 1.[0123].* ]] && [ ! -f "${cw_ROOT}"/etc/config.yml ]; then
          cat <<EOF
Configuration of this node has $(echo -e "\e[1;31m")not yet been completed$(echo -e "\e[0m") and it is not yet
operational.

Please proceed with configuration by running the "$(echo -e "\e[1;37m")alces configure$(echo -e "\e[0m")" command.

EOF
        else
          cat <<EOF
Configuration of this node has not yet been completed and it is not yet
operational.  When configuration is complete you will receive a notice at
the prompt.  Additionally, the prompt will be updated to include the name of
the cluster.

EOF
        fi
      fi
    fi
  fi
fi
unset cw_SETTINGS_skip_motd cw_SETTINGS_skip_banner cw_SETTINGS_skip_status cw_VERSION cw_STATUS
