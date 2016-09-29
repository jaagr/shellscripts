#!/usr/bin/env bash

test '[post-pass:require-fn=log::_format]'
declare -gx __LOG_FORMAT="icons"
declare -gx __LOG_PENDING_PAD=0
test '[/post-pass:require-fn]'

function log::_format
{
  local ansi=$1 ; shift
  local icon=$1 ; shift
  printf "\033[%sm%s\033[22;39m %s\033[0m" "$ansi" "$icon" "$*"
}

function log::format::log {
  echo "0"
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
  echo "+"
}
function log::prefix::debug {
  echo "d"
}
function log::prefix::info {
  echo "i"
}
function log::prefix::ok {
  echo "✓"
}
function log::prefix::warn {
  echo "!"
}
function log::prefix::err {
  echo "✘"
}
function log::prefix::fatal {
  echo "✘"
}
