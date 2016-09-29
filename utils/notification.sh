#!/usr/bin/env bash
#
# Interface for sending notifications using libnotify
#   jaagr <c@rlberg.se>
#

function notification::__send {
  local urgency="$1" ; shift
  /usr/bin/notify-send -u "$urgency" "$@"
}

function notification::low {
  notification::__send "low" "$@"
}

function notification::normal {
  notification::__send "normal" "$@"
}

function notification::critical {
  notification::__send "critical" "$@"
}
