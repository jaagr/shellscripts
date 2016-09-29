#!/usr/bin/env bash

function is_root {
  [[ "$(id -u)" -eq "0" ]]
}

function previous_cmd_successful {
  [[ "$?" -eq "0" ]]
}

function in_array
{
  for item in $2; do
    [[ "${item}" = "$1" ]] && return 0
  done
  return 1
}
