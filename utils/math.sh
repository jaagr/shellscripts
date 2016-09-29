#!/usr/bin/env bash
#
# Math utility functions for
#   jaagr <c@rlberg.se>
#

function math::min {
  (( $(math::float "$1" .0) < $(math::float "$2" .0) )) && echo "$1" || echo "$2"
}

function math::max {
  (( $(math::float "$1" .0) > $(math::float "$2" .0) )) && echo "$1" || echo "$2"
}

function math::float {
  printf "%${2:-.2}f" "$(echo "$1" | bc -l)"
}

function math::round {
  printf "%1.0f" "$(math::float "$1")"
}

function math::percentage {
  local value="$1"
  local total="$2"
  local decimals="$3"
  math::float "$(echo "${value} / ${total} * 100.0" | bc -l)" "${decimals}"
}

function math::percentage_of {
  local percentage="$1"
  local value="$2"
  local decimals="$3"
  math::float "$(echo "${percentage} * ${value} / 100.0" | bc -l)" "${decimals}"
}

function math::percentage_to_hex {
  printf "%02X" "$(math::round "$1 / 100.0 * 255.0")"
}

function math::bytes {
  math::round "$(echo "$1" | sed 's/.*/\L\0/;s/t/Xg/;s/g/Xm/;s/m/Xk/;s/k/X/;s/b//;s/X/ *1024/g')"
}
