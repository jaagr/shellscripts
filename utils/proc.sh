#!/usr/bin/env bash
#
# Helper functions for running processes
#   jaagr <c@rlberg.se>
#

include utils/log/defer.sh
include utils/spinner.sh

function proc::wait
{
  local pid="$1" ; shift
  local outbuf
  local -i num=0

  ansi::extend_buffer

  log::defer "${1:-waiting for pid} $(ansi::colorize "31" "$pid") $(ansi::save_position)"

  while [ -d "/proc/${pid}" ]; do
    ansi::restore_position

    spinner::get outbuf num "spin_11"

    echo -e "]──${outbuf} "

    sleep 0.15
  done

  ansi::restore_position

  log::defer::success "Process finished"
}

function proc::run_and_wait
{
  "$SHELL" -c "$1" &
  proc::wait "$!"
}
