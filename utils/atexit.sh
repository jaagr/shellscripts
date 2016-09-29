#!/usr/bin/env bash

function sigaction {
  trap - INT TERM QUIT 0
  declare -f atexit >/dev/null && atexit
}

trap sigaction INT TERM QUIT 0
