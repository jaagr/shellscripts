#!/usr/bin/env bash
#
# Lemonbuddy utility funtions
#   jaagr <c@rlberg.se>
#

include utils/_.sh

function lemonbuddy::config_value
{
  if [[ $# -lt 3 ]]; then
    _::stderr "parameters: config bar parameter [fallback]"; exit 1
  fi

  local config="$1"; shift
  local bar="$1"; shift
  local parameter="$1"; shift
  local fallback="$1"

  lemonbuddy "$bar" --config="$config" --dump="$parameter" 2>/dev/null || echo "$fallback"
}

function lemonbuddy::alignment
{
  if [[ $# -lt 2 ]]; then
    _::stderr "parameters: config bar"; exit 1
  fi

  local config="$1"; shift
  local bar="$1"; shift

  if [[ "$(lemonbuddy::config_value "$config" "$bar" bottom)" == "true" ]]; then
    echo bottom
  else
    echo top
  fi
}

function lemonbuddy::wm_name
{
  if [[ $# -lt 2 ]]; then
    _::stderr "parameters: config bar"; exit 1
  fi

  lemonbuddy "$2" --config="$1" --print-wmname 2>/dev/null
}

# shellcheck disable=2155
function lemonbuddy::drawline
{
  if [[ $# -lt 4 ]]; then
    _::stderr "parameters: config monitor bar color [offset_y=0] [height=1]"; return 1
  fi

  local config="$1"; shift
  local monitor="$1"; shift
  local bar="$1"; shift
  local color="$1"; shift
  local offset_y="${1:-0}"
  local height="${2:-1}"
  local align="$(lemonbuddy::alignment "$config" "$bar")"
  local wmname="$(lemonbuddy::wm_name "$config" "$bar")"
  local w=$(lemonbuddy::config_value "$config" "$bar" width 100%)
  local h=$(lemonbuddy::config_value "$config" "$bar" height 0)
  local x=$(lemonbuddy::config_value "$config" "$bar" offset-x 0)
  local y=$(lemonbuddy::config_value "$config" "$bar" offset-y 0)
  local bt=$(lemonbuddy::config_value "$config" "$bar" border-top 0)
  local bb=$(lemonbuddy::config_value "$config" "$bar" border-bottom 0)

  xdrawrect "$monitor" "$align" "$w" "$height" "$x" "$((h+y+bt+bb+offset_y))" "$color" "effectline-${monitor}-${align}" "$wmname"
}
