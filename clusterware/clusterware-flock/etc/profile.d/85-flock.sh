################################################################################
##
## Alces Clusterware - Shell configuration
## Copyright (c) 2018 Alces Software Ltd
##
################################################################################
if [ "$(id -u)" != "0" ]; then
   "${cw_ROOT}"/libexec/share/spinner "Updating flock" &
    spinner_pid="$!"
    # XXX - verify flockd is running before we try any of this
    . "${cw_ROOT}"/etc/flock.rc
    cw_FLOCK_mnt="${cw_FLOCK_mnt:-/mnt/flight}"
    _ALCES="${cw_ROOT}"/bin/alces

    if [ ! -f ~/.config/flock/token ]; then
        mkdir -p ~/.config/flock
        _token="$(uuid -v4)"
        echo "${_token}" > ~/.config/flock/token
        ${_ALCES} flock trigger sync-auth-tokens
    else
      _token="$(cat ~/.config/flock/token)"
    fi

    if [ -f ~/.ssh/id_alcescluster.pub ]; then
        _md5=$(md5sum ~/.ssh/id_alcescluster.pub | cut -c1-8)
        _sshkey="user.$(id -u).sshkey.${_md5}"
        ${_ALCES} flock set ${_sshkey} "$(cat ~/.ssh/id_alcescluster.pub)" "${_token}" &>/dev/null
    fi

    "${_ALCES}" flock trigger mount-imports
    shopt -s nullglob
    for a in ${cw_FLOCK_mnt}/targets/*; do
      aa=$(basename "$a")
      for b in $a/*; do
        bb=$(basename "$b")
        mkdir -p ${cw_FLOCK_mnt}/users/$(id -un)
        ln -snf $b/$(id -un) ${cw_FLOCK_mnt}/users/$(id -un)/$aa-$bb
      done
    done
    shopt -u nullglob
    unset a b aa bb
    unset _token _sshkey _val _ALCES _md5
    unset cw_FLOCK_mnt
    kill -USR1 $spinner_pid
    wait $spinner_pid
    unset spinner_pid
fi
