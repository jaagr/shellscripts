#!/usr/bin/env bash
#
# Set of functions used internally by the utils

function _::stdout {
  echo "${FUNCNAME[1]} -> $*"
}

function _::stderr {
  echo "${FUNCNAME[1]} -> $*" >&2
}

function _::geom {
  echo "${1//[^0-9]/}x${2//[^0-9]/}+${3//[^0-9]/}+${4//[^0-9]/}"
}
