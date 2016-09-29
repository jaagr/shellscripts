#!/usr/bin/env bash

# shellcheck disable=2155
function log::banner
{
  local spaces=$1 ; shift
  local msg="$1" ; shift
  local ansi_attrs="${1:-41;37;1}"
  local length="${#msg}"
  local padding=$(printf "%*s" $(( (spaces - length) / 2 )))
  local diff=$(( ${#padding} * 2 + length - spaces ))

  if [[ ${diff:0:1} == "-" ]]; then
    diff=${diff:1}
  fi

  if [[ $diff -eq 1 ]]; then
    msg="$msg "
  elif [[ $diff -gt 1 ]]; then
    hdiff=$((diff/2))
    echo $diff
    msg="$(printf "%*s" $hdiff " ")$msg$(printf "%*s" $hdiff " ")"
  fi

  echo -e "\033[${ansi_attrs}m${padding}${msg}${padding}\033[0m"
}
