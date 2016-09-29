#!/usr/bin/env bash

include utils/log.sh
include utils/ansi.sh
include utils/keycode.sh

test '[post-pass:require-fn=log::defer]'
declare -gx __LOG_PENDING=0
declare -gx __LOG_PENDING_MSG
test '[/post-pass:require-fn]'

function log::defer
{
  # assume success for last log since no error was reported
  log::defer::_finish_pending
  ansi::beginning
  printf "%s" "$(log "$@")"
  __LOG_PENDING_MSG="$*"
  __LOG_PENDING=1
  trap 'log::defer::_finish_pending' EXIT
}

function log::defer::_finish_pending
{
  if [[ $__LOG_PENDING -eq 1 ]]; then
    log::defer::success
  fi
}

function log::defer::_describe
{
  local color="$1" ; shift
  printf "%${__LOG_PENDING_PAD}s"
  [[ "$__LOG_FORMAT" == "tags" ]] && printf " "
  if ansi::check_support; then
    printf "\033[1;${color}m\U2570\U2500\U2500\U2578\033[0m %s\n" "$@"
  else
    printf "%s\n" "$@"
  fi
}

function log::defer::success
{
  local msg=${1:-$__LOG_PENDING_MSG} ; shift
  ansi::beginning
  if [[ "$msg" ]]; then
    ansi::check_support && ansi::clear_line
    ansi::check_support || printf "\n"
  fi
  log::ok "$msg"
  [[ $# -gt 0 ]] && log::defer::_describe "32" "$@"
  __LOG_PENDING=0
}

function log::defer::failure
{
  local msg=${1:-$__LOG_PENDING_MSG} ; shift
  ansi::beginning
  if [[ "$msg" ]]; then
    ansi::check_support && ansi::clear_line
    ansi::check_support || printf "\n"
  fi
  log::err "$msg"
  [[ $# -gt 0 ]] && 1>&2 log::defer::_describe "31" "$@"
  __LOG_PENDING=0
}

function log::defer::other
{
  local msg=$1 ; shift
  ansi::beginning
  if [[ "$msg" ]]; then
    ansi::check_support && ansi::clear_line
    ansi::check_support || printf "\n"
  fi
  log "$msg"
  [[ $# -gt 0 ]] && log::defer::_describe "32" "$@"
  __LOG_PENDING=0
}

function log::defer::countdown
{
  local -n retval=$1 ; shift
  local -i seconds=$1 ; shift
  local -i timer
  local key

  ansi::extend_buffer
  log::defer "$(ansi::save_position)" "${@//%s/0}"

  seconds+=1;

  while (( --seconds > 0 )); do
    ansi::restore_position

    echo "${@//%s/$seconds}"

    read -s -r -N1 -t 1 key
    timer=$?

    if [[ $seconds -eq 1 ]]; then
      retval=2 ; break
    elif keycode::match_esc "$key" || [[ "$key" == "q" ]]; then
      retval=1 ; break
    elif [[ $timer -ne 142 ]]; then
      retval=0 ; break
    fi
  done

  ansi::restore_position
}

function log::defer::cmd
{
  local fail_with_details='true'
  local err

  if [[ "$1" == 'true' ]]; then
    fail_with_details='true'; shift
  elif [[ "$1" == 'false' ]]; then
    fail_with_details='false'; shift
  fi

  err=$(/bin/sh -c "$@" 2>&1 >/dev/null)

  if [[ -n "$err" ]]; then
    if $fail_with_details; then
      log::defer::failure "" "$err"
    else
      log::defer::failure
    fi
    return 1
  fi

  log::defer::success
}
