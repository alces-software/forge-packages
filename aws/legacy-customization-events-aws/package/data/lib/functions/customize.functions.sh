#==============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Clusterware.
#
# Alces Clusterware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Clusterware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Clusterware, please visit:
# https://github.com/alces-software/clusterware
#==============================================================================

# This is a stripped-down version of the customize.functions.sh contained in previous
# versions of Clusterware, designed to provide a degree of backwards-compatibility
# for Forge-based clusters

require files
require network

customize_run_hooks() {
  local a p hook paths profile profile_found
  hook="$1"
  if [[ "$hook" == *":"* ]]; then
    profile=$(echo "${hook#*:}" | sed -e 's/\//-/g')
    hook="${hook%:*}"
  fi
  shift
  files_load_config config config/cluster
  files_load_config instance config/cluster
  files_load_config cluster-customizer

  cw_CLUSTER_CUSTOMIZER_path=${cw_CLUSTER_CUSTOMIZER_path:-"${cw_ROOT}"/var/lib/customizer-compat}
  # Let's not support custom paths, to simplify

  for p in ${cw_CLUSTER_CUSTOMIZER_path}/*; do
    if [[ -z "${profile}" || "${p}" == */"${profile}" ]]; then
      profile_found=true
      if [ -d "${p}"/${hook}.d ]; then
        for a in "${p}"/${hook}.d/*; do
          if [ -x "$a" -a ! -d "$a" ] && [[ "$a" != *~ ]]; then
            echo "Running $hook hook: ${a}"
            "${a}" "${hook}" \
                    "${cw_INSTANCE_role}" \
                    "${cw_CLUSTER_name}" \
                    "$@"
          elif [[ "$a" != *~ ]]; then
            echo "Skipping non-executable $hook hook: ${a}"
          fi
        done
      else
          echo "No $hook hooks found in ${p}"
      fi
    fi
  done
  if [ -z "${profile_found}" ]; then
    return 1
  fi
}

customize_fetch_profile() {
  local s3cfg source target host manifest f s3cmd excludes
  s3cfg="$1"
  source="$2"
  target="$3"
  excludes="$4"
  mkdir -p "${target}"
  if [ "${s3cfg}" ]; then
    # Create bucket if it does not already exist
    "${cw_ROOT}"/opt/s3cmd/s3cmd -c ${s3cfg} mb "s3://${source%%/*}" &>/dev/null
    local args
    args=(--force -r)
    if [ -n "${excludes}" ] ; then
      args+=(--exclude)
      args+=(${excludes})
    fi
    "${cw_ROOT}"/opt/s3cmd/s3cmd -c ${s3cfg} ${args[@]} get "s3://${source}"/ "${target}"
    if rmdir "${target}" 2>/dev/null; then
      echo "No profile found for: ${source}"
      return 1
    fi
  else
    # fetch manifest file
    if [ "${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}" == "us-east-1" ]; then
        host=s3.amazonaws.com
    else
        host=s3-${_REGION:-${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}}.amazonaws.com
    fi
    manifest=$(curl -s -f https://${host}/${source}/manifest.txt)
    if [ "${manifest}" ] && ! echo "${manifest[*]}" | grep -q '<Error>'; then
      # fetch each file within manifest file
      for f in ${manifest}; do
        mkdir -p "${target}/$(dirname "$f")"
        if curl -s -f -o ${target}/${f} https://${host}/${source}/${f}; then
          echo "Fetched: ${source}/${f}"
        else
          echo "Unable to fetch: ${source}/${f}"
          return 1
        fi
      done
    else
      echo "No manifest found for: ${source}. A manifest file is required when S3 access is unavailable."
      return 1
    fi
  fi
}

customize_fetch_account_profiles() {
  local bucket profile s3cfg
  s3cfg=$1

  files_load_config cluster-customizer

  if [ -z "${cw_CLUSTER_CUSTOMIZER_bucket}" ]; then
    if network_is_ec2; then
        bucket="alces-flight-$(network_ec2_hashed_account)"
    else
        echo "Unable to determine bucket name for customizations"
        return 0
    fi
  else
    bucket="${cw_CLUSTER_CUSTOMIZER_bucket#s3://}"
  fi
  if ! customize_is_s3_access_available "${s3cfg}" "${bucket}"; then
    echo "S3 access to '${bucket}' is not available.  Falling back to HTTP manifests."
    s3cfg=""
  fi
  for profile in ${cw_CLUSTER_CUSTOMIZER_account_profiles}; do
    echo "Retrieving customizations from: ${bucket}/customizer/$profile"
    customize_fetch_profile "${s3cfg}" "${bucket}"/customizer/"${profile}" \
                            "${cw_CLUSTER_CUSTOMIZER_path}"/account-${profile} \
                            "*job-queue.d/*"
  done
}

customize_is_s3_access_available() {
  local s3cfg bucket
  s3cfg="$1"
  bucket="$2"
  "${cw_ROOT}"/opt/s3cmd/s3cmd -q -c ${s3cfg} ls "s3://${bucket}" 2>/dev/null
}

customize_set_region() {
  if [ -z "${_REGION}" ]; then
    if network_is_ec2; then
      eval $(network_fetch_ec2_document | "${cw_ROOT}"/opt/jq/bin/jq -r '"_REGION=\(.region)"')
    else
      _REGION="${cw_CLUSTER_CUSTOMIZER_region:-eu-west-1}"
    fi
  fi
}

customize_set_s3_config() {
  customize_set_region
  s3cfg="$(mktemp /tmp/cluster-customizer.s3cfg.XXXXXXXX)"
  cat <<EOF > "${s3cfg}"
[default]
access_key = "${cw_CLUSTER_CUSTOMIZER_access_key_id}"
secret_key = "${cw_CLUSTER_CUSTOMIZER_secret_access_key}"
security_token = ""
use_https = True
check_ssl_certificate = True
EOF
}

customize_clear_s3_config() {
  rm -f "${s3cfg}"
  unset s3cfg
}

customize_fetch() {
  files_load_config cluster-customizer

  cw_CLUSTER_CUSTOMIZER_path="${cw_CLUSTER_CUSTOMIZER_path:-${cw_ROOT}/var/lib/customizer-compat}"

  customize_set_s3_config
  mkdir -p "${cw_CLUSTER_CUSTOMIZER_path}"
  customize_fetch_account_profiles "${s3cfg}"
  chmod -R a+x "${cw_CLUSTER_CUSTOMIZER_path}"
  customize_clear_s3_config
}
