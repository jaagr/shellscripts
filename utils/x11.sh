#!/usr/bin/env bash
#
# x11 utility functions
#   jaagr <c@rlberg.se>

function x11::monitor_connected {
  xrandr --query | grep -q "^$1 connected" || \
    xrandr --query | grep -q "^${1//-/} connected"
}

function x11::monitor_geom {
  xrandr --query \
    | egrep "^$1 (dis)?connected" \
    | egrep -o "[0-9]+x[0-9]+\+[0-9]*\+[0-9]*"
}

function x11::wmname_win {
  2>/dev/null xwininfo -name "$1" \
    | sed -nr "/Window id/s/.*0x([[:xdigit:]]+).*/\1/p" \
    | xargs -r printf "0x%8s\n" \
    | tr " " "0"
}

function x11::root_win {
  2>/dev/null xwininfo -root \
    | sed -nr "/Window id/s/.*(0x[[:xdigit:]]+).*/\1/p" \
    | xargs -r printf "0x%8s\n" \
    | tr " " "0"
}

# In bspwm, the root window for the specified monitor
# can be matched against a window with the same geometry
# and WM_CLASS instance set to "root"
function x11::root_win_bspwm {
  if x11::monitor_connected "$1"; then
    xwininfo -root -children \
      | grep "root.*[bB]spwm" \
      | grep "$(x11::monitor_geom "$1")" \
      | sed -nr "s/^[ ]+ 0x([[:xdigit:]]+).*/\1/p" \
      | xargs -r printf "0x%8s\n" \
      | tr " " "0"
  fi
}

# In i3, the root window for the specified monitor
# can be matched against the wm_name "[i3 con] output ${monitor}"
function x11::root_win_i3 {
  if x11::monitor_connected "$1"; then
    x11::wmname_win "[i3 con] output $1"
  fi
}
