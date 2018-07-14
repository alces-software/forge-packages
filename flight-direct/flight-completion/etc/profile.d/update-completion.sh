#
# This scripts updates the forge bash completion
#

flight ruby "$FL_ROOT"/scripts/completion.rb
if [[ -f "$FL_ROOT"/scripts/bash_completion.sh ]]; then
  source "$FL_ROOT"/scripts/bash_completion.sh
fi

