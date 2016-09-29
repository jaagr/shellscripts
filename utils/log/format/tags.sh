#!/usr/bin/env bash

test '[post-pass:require-fn=log::_format]'
declare -gx __LOG_FORMAT="tags"
declare -gx __LOG_TAG_FORMAT=1
declare -gx __LOG_TAG_PAD=5
declare -gx __LOG_PENDING_PAD=3
test '[/post-pass:require-fn]'

function log::_format
{
  local ansi=$1 ; shift
  local tag=$1 ; shift

  if [[ "$__LOG_TAG_FORMAT" -eq 2 ]]; then
    printf "\033[%sm%*s** \033[0m%s" "$ansi" "$__LOG_TAG_PAD" "" "$*"
  else
    printf "\033[%sm%*s \033[0;1;37m** \033[0m%s" "$ansi" "$__LOG_TAG_PAD" "$tag" "$*"
  fi
}

function log::format::log {
  echo "2;37"
}
function log::format::debug {
  echo "1;35"
}
function log::format::info {
  echo "1;36"
}
function log::format::ok {
  echo "1;32"
}
function log::format::warn {
  echo "1;33"
}
function log::format::err {
  echo "1;31"
}
function log::format::fatal {
  echo "1;31"
}

function log::prefix::log {
  echo "log"
}
function log::prefix::debug {
  echo "debug"
}
function log::prefix::info {
  echo "info"
}
function log::prefix::ok {
  echo "ok"
}
function log::prefix::warn {
  echo "warn"
}
function log::prefix::err {
  echo "err"
}
function log::prefix::fatal {
  echo "fatal"
}
