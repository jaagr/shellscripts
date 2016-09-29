#!/usr/bin/env bash

source bootstrap.sh

include utils/testkit.sh
include utils/color.sh

bootstrap::finish

function main
{
  testkit::equals "color::brightness '#ffffff' 25" "#404040"
  testkit::equals "color::brightness '#ffffff' 100" "#ffffff"
  testkit::equals "color::brightness '#000000' 13" "#000000"
  testkit::equals "color::brightness '#f9213c' 100" "#f9213c"
  testkit::equals "color::brightness '#c89abd' 50" "#644d5e"
  testkit::equals "color::brightness '#000' 50" "#000000"
  testkit::equals "color::brightness '#pp' 50" ""
}

main "$@"
