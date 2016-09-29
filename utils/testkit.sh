#!/usr/bin/env bash

include utils/log.sh
include utils/log/defer.sh

load utils/log/format/icons.sh

export __LOG_TAG_PAD=3

function testkit::equals
{
  local input=$1
  local expected_result=$2
  local actual_result

  actual_result="$(eval "${input}" 2>/dev/null)"

  if [[ "${actual_result}" == "${expected_result}" ]]; then
    log::ok "${input} \e[2m=\e[0m ${expected_result}"
  else
    log::err "Test failed"
    echo -e "\e[2m   Input\e[0m ${input}"
    echo -e "\e[2mExpected\e[0m ${expected_result}"
    echo -e "\e[2m  Actual\e[0m ${actual_result}"
  fi
}

function testkit::match_strings
{
  local str=$1
  local expected_str=$2

  if [[ "${str}" == "${expected_str}" ]]; then
    log::ok "${str} \e[2m=\e[0m matched the expected string"
  else
    log::err "Test failed"
    echo -e "\e[2mExpected\e[0m ${expected_str}"
    echo -e "\e[2mActual  \e[0m ${str}"
  fi
}
