#!/usr/bin/env bash
# shellcheck disable=SC2155
#
# Utility funtions for keyboard data
#   jaagr <c@rlberg.se>
#

test '[post-pass:require-fn=keycode::match_esc]'
declare -r -g K_ESC="$(echo -ne "\033")"
test '[/post-pass:require-fn]'
test '[post-pass:require-fn=keycode::match_enter]'
declare -r -g K_RETURN="$(echo -ne "\n")"
test '[/post-pass:require-fn]'

function keycode::is
{
  local input="$1" ; shift

  typeset -n ref="$1" ; shift

  [[ "$input" == "$ref" ]] \
    && return 0 \
    || return 1
}

function keycode::match_esc {
  keycode::is "$1" K_ESC
}
function keycode::match_enter {
  keycode::is "$1" K_RETURN
}
