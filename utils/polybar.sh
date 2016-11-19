#!/usr/bin/env bash
#
# Polybar utility funtions
#   jaagr <c@rlberg.se>
#

include utils/_.sh

function polybar::config_value
{
  if [[ $# -lt 3 ]]; then
    _::stderr "parameters: config bar parameter [fallback]"; exit 1
  fi

  local config="$1"; shift
  local bar="$1"; shift
  local parameter="$1"; shift
  local fallback="$1"

  polybar "$bar" --config="$config" --dump="$parameter" 2>/dev/null || echo "$fallback"
}

function polybar::alignment
{
  if [[ $# -lt 2 ]]; then
    _::stderr "parameters: config bar"; exit 1
  fi

  local config="$1"; shift
  local bar="$1"; shift

  if [[ "$(polybar::config_value "$config" "$bar" bottom)" == "true" ]]; then
    echo bottom
  else
    echo top
  fi
}

function polybar::wm_name
{
  if [[ $# -lt 2 ]]; then
    _::stderr "parameters: config bar"; exit 1
  fi

  polybar "$2" --config="$1" --print-wmname 2>/dev/null
}

# shellcheck disable=2155
function polybar::drawline
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
  local align="$(polybar::alignment "$config" "$bar")"
  local wmname="$(polybar::wm_name "$config" "$bar")"
  local w=$(polybar::config_value "$config" "$bar" width 100%)
  local h=$(polybar::config_value "$config" "$bar" height 0)
  local x=$(polybar::config_value "$config" "$bar" offset-x 0)
  local y=$(polybar::config_value "$config" "$bar" offset-y 0)
  local bt=$(polybar::config_value "$config" "$bar" border-top 0)
  local bb=$(polybar::config_value "$config" "$bar" border-bottom 0)

  xdrawrect "$monitor" "$align" "$w" "$height" "$x" "$((h+y+bt+bb+offset_y))" "$color" "effectline-${monitor}-${align}" "$wmname"
}
