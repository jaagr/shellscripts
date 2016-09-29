#!/usr/bin/env bash

include utils/ansi.sh

function log::_format {
  shift
  shift
  printf "%s" "$*"
}

function log::debug {
  if ansi::check_support; then
    echo -e "$(log::_format "$(log::format::debug)" "$(log::prefix::debug)" "$@")"
  else
    echo "[debug] $*"
  fi
}

function log::info {
  if ansi::check_support; then
    echo -e "$(log::_format "$(log::format::info)" "$(log::prefix::info)" "$@")"
  else
    echo "[info] $*"
  fi
}

function log::ok {
  if ansi::check_support; then
    echo -e "$(log::_format "$(log::format::ok)" "$(log::prefix::ok)" "$@")"
  else
    echo "[ok] $*"
  fi
}

function log::warn {
  if ansi::check_support; then
    echo 1>&2 -e "$(log::_format "$(log::format::warn)" "$(log::prefix::warn)" "$@")"
  else
    echo "[warn] $*"
  fi
}

function log::err {
  if ansi::check_support; then
    echo 1>&2 -e "$(log::_format "$(log::format::err)" "$(log::prefix::err)" "$@")"
  else
    echo "[err] $*"
  fi
}

function log::fatal {
  if ansi::check_support; then
    echo 1>&2 -e "$(log::_format "$(log::format::fatal)" "$(log::prefix::fatal)" "$@")"
  else
    echo "[fatal] $*"
  fi
}

function log {
  if ansi::check_support; then
    echo -e "$(log::_format "$(log::format::log)" "$(log::prefix::log)" "$@")"
  else
    echo "$@"
  fi
}

function log::prompt {
  prompt="$(log "$@")"
  read -p "$prompt" -N 1 -r __LOG_PROMPT_VALUE
}
