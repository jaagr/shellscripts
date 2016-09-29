#!/usr/bin/env bash
#
# Alsa utility functions
#   jaagr <c@rlberg.se>
#

function alsa::get_card_index {
  amixer controls | sed -nr "s/^numid=([0-9]+).*CARD.*${1}.*/\1/p"
}

function alsa::is_connected {
  amixer cget "numid=$1" | sed -rn '$!d;/=on$/!q1' \
    && return 0 \
    || return 1
}

function alsa::get_volume {
  amixer sget "${1},0" | sed -nr 's/.*\[([0-9]+)%\].*/\1/p'
}

function alsa::set_volume {
  amixer -q set "${1},0" "${2}%"
}

function alsa::is_muted {
  amixer sget "${1},0" | sed -rn '$!d;/\[off\]$/!q1' \
    && return 0 \
    || return 1
}

function alsa::mute {
  local mixer="$1" ; shift
  local mode

  [[ $# -gt 0 ]] && mode=$1 || mode='true'

  if $mode; then
    amixer -q set "$mixer" off
  else
    amixer -q set "$mixer" on
  fi
}

function alsa::unmute {
  alsa::mute "$1" 'false'
}
