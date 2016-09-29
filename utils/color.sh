#!/usr/bin/env bash
#
# Utility funtions for colors
#   jaagr <c@rlberg.se>
#

include utils/math.sh
include utils/log.sh

function color::brightness {
  local hex=${1//[^[:xdigit:]]/}; shift
  local perc=$((100-$1))

  [[ ${#hex} -eq 3 ]] && {
    hex="${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}"
  }

  [[ ${#hex} -ne 6 ]] && {
    log::err "Invalid hex color \"${hex}\""; return 1
  }

  local rgb str val i;

  for (( i=0 ; i<3 ; i+=1 )); do
    val="$(printf "%2f" "0x${hex:$((i*2)):2}")"
    val="$(math::float "${val}-(${perc}*(${val}/100))")"
    val="$(math::round "$val")"
    val="$(math::min "$val" 255)"
    val="$(math::max "$val" 0)"
    str="0$(printf "%x" "$val")"
    rgb="${rgb}${str:(-2)}"
  done

  echo "#${rgb}"
}
