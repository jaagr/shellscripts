#!/usr/bin/env bash
#
# Utility funtions for json data
#   jaagr <c@rlberg.se>
#

function json::get_value {
  echo "$1" | jq ".$2"
}
