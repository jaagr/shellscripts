#!/usr/bin/env bash
#
# Utility functions for managing named pipes
#   jaagr <c@rlberg.se>
#

pipe=""

trap 'pipe::close' EXIT

# fd=3
# eval "exec $fd<> $fifo"

function pipe::open
{
  [ -z "$pipe" ] && {
    pipe=$(mktemp -u);
  }
  [ -p "$pipe" ] || {
    mkfifo "$pipe"
    exec 3<> "$pipe"
  }
}

function pipe::close
{
  [ -p "$pipe" ] && {
    rm "$pipe"
    exec 3>&-
  }
}

function pipe::push
{
  pipe::open
  echo "$@" >&3
}

function pipe::peek
{
  read -r "$1" <&3
}

function pipe::tail
{
  while read -r line <&3; do
    if [[ "$line" == "EOF" ]]; then
      break;
    fi
    echo "$line"
  done
}
