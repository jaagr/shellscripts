#!/usr/bin/env bash

function str::unicode {
  printf "%b" "\u$1"
}

function str::upper {
  tr '[:lower:]' '[:upper:]' <<< "$@"
}

function str::lower {
  tr '[:upper:]' '[:lower:]' <<< "$@"
}

function str::trim {
  sed -r 's/^\s*(\S)|(\S*)\s*$/\1\2/g' <<< "$@"
}

function str::pad
{
  local width="$1" ; shift
  local str="$1" ; shift
  printf "%*b" "$width" "$str"
}

function str::right {
  str::pad "$(tput cols)" "$@"
}

function str::center
{
  local str cols rows
  str="$1" ; shift
  cols=$(tput cols)
  rows=$(tput lines)
  tput cup $(( rows / 2 )) $(( cols / 2 - ${#str} / 2 ))
  printf "%b" "${str}"
}

function str::shift_right
{
  local -i width=$1
  local fill="${2:- }"
  local shift_str

  shift_str="$(printf "%*s" "$width" "$fill")"
  shift_str="${shift_str// /$fill}"

  while read -r line; do
    echo -e "${shift_str}${line}"
  done
}
