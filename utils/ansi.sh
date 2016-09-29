#!/usr/bin/env bash
#
# Utility functions for handling terminal output/formatting
#   jaagr <c@rlberg.se>
#

test '[post-pass:require-fn=ansi::check_support]'
declare -gx __ANSI_SUPPORT='true'

if ! [[ -t 1 ]]; then
  __ANSI_SUPPORT='false'
fi
test '[/post-pass:require-fn]'

function ansi::check_support {
  $__ANSI_SUPPORT || [[ -t 1 ]] \
    && return 0 \
    || return 1
}

function ansi {
  if ansi::check_support; then
    printf "\033[%s" "$*"
  fi
}

function ansi::reset {
  ansi "0m"
}

function ansi::colorize {
  local colors=$1 ; shift
  ansi "${colors}m"
  printf "%s" "$*"
  ansi::reset
}

function ansi::bold {
  ansi "1m"
  printf "%s" "$*"
  ansi::reset
}

function ansi::italic {
  ansi "3m"
  printf "%s" "$*"
  ansi::reset
}

function ansi::conceal {
  ansi "8m"
  printf "%s" "$*"
  ansi::reset
}

function ansi::strikethrough {
  ansi "9m"
  printf "%s" "$*"
  ansi::reset
}

function ansi::beginning {
  printf "\r"
}

function ansi::up {
  ansi "${1}A"
}

function ansi::down {
  ansi "${1}B"
}

function ansi::left {
  ansi "${1}D"
}

function ansi::right {
  ansi "${1}C"
}

function ansi::line_up {
  ansi "${1}F"
}

function ansi::line_down {
  ansi "${1}E"
}

function ansi::move {
  local rows=$1 ; shift
  local cols=$1 ; shift

  if [[ $rows -lt 0 ]]; then
    ansi::up "${rows:1}"
  elif [[ $rows -gt 0 ]]; then
    ansi::down "$rows"
  fi

  if [[ $cols -lt 0 ]]; then
    ansi::left "${cols:1}"
  elif [[ $cols -gt 0 ]]; then
    ansi::right "$cols"
  fi
}

function ansi::move_absolute {
  local row=$1 ; shift
  local col=$1 ; shift
  ansi "${row};${col}f"
}

function ansi::save_position {
  ansi "s"
}

function ansi::restore_position {
  ansi "u"
}

function ansi::clear_screen {
  ansi::beginning
  ansi "2J"
}

function ansi::clear_lines_before {
  ansi::beginning
  ansi "1J"
}

function ansi::clear_lines_after {
  ansi::beginning
  ansi "0J"
}

function ansi::clear_line {
  ansi::beginning
  ansi "K"
}

function ansi::extend_buffer {
  if ansi::check_support; then
    printf "\n\n"
    ansi::line_up 2
  fi
}

#function ansi::is_last_line {
#  local report
#  report=$(ansi "6n")
#}

function ansi::draw_line {
  if ansi::check_support; then
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | sed -n -r "s/ /${1:-─}/gp"
  fi
}
