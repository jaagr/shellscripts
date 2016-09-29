#!/usr/bin/env bash

source bootstrap.sh

include utils/testkit.sh
include utils/spinner.sh

bootstrap::finish

function test_name_ref_update
{
  local a
  local -i b=0
  spinner::get a b misc_1
  echo "$a"
}

function test_name_ref_update2
{
  local a
  local -i b=1
  spinner::get a b
  echo "$b"
}

function main
{
  local -i frame=0

  # test that get() sets the output reference
  testkit::equals "test_name_ref_update" "d"

  # test that get() increments the index reference
  testkit::equals "test_name_ref_update2" "2"

  testkit::equals "spinner::print frame" "⣷"
  let frame++ # Fake the name ref update

  testkit::equals "spinner::print frame" "⣯"
  let frame++ # Fake the name ref update

  testkit::equals "spinner::print frame" "⣟"
  let frame++ # Fake the name ref update

  testkit::equals "spinner::print frame" "⡿"


  local buffer out

  let frame=0
  spinner::get out frame misc_2 q
  buffer+=$out

  let frame=4
  spinner::get out frame grow_3
  buffer+=$out

  testkit::match_strings "$buffer" "q*"
}

main "$@"
