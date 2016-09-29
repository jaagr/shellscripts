#!/usr/bin/env bash

test '[post-pass:require-fn=log::_format]'
declare -gx __LOG_FORMAT="blocks"
declare -gx __LOG_TAG_FORMAT=1
declare -gx __LOG_PENDING_PAD=5
test '[/post-pass:require-fn]'

function log::_format
{
  local ansi=$1 ; shift
  local tag=$1 ; shift

  printf "\033[%sm%6s \033[0;1;37m \033[0m%s" "$ansi" "$tag" "$*"
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

function log::format::log {
  echo "30;47"
}
function log::format::debug {
  echo "30;45"
}
function log::format::info {
  echo "30;46"
}
function log::format::ok {
  echo "30;42"
}
function log::format::warn {
  echo "30;43"
}
function log::format::err {
  echo "30;41"
}
function log::format::fatal {
  echo "30;41"
}
