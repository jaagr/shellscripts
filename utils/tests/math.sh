#!/usr/bin/env bash

source bootstrap.sh

include utils/testkit.sh
include utils/math.sh

bootstrap::finish

function main
{
  testkit::equals "math::min 3 9" "3"
  testkit::equals "math::min 3.300 3.5" "3.300"

  testkit::equals "math::max 9 8" "9"
  testkit::equals "math::max 3.300 3.5" "3.5"

  testkit::equals "math::float '1 / 5'" "0.20"
  testkit::equals "math::float '1 / 5' 0.5" "0.20000"

  testkit::equals "math::round 1" "1"
  testkit::equals "math::round 3.25" "3"
  testkit::equals "math::round 5.893" "6"

  testkit::equals "math::percentage 3.25 50" "6.50"
  testkit::equals "math::percentage 25 100 .0" "25"

  testkit::equals "math::percentage_of 1 125 0.4" "1.2500"
  testkit::equals "math::percentage_of 80 10" "8.00"
  testkit::equals "math::percentage_of 120 10" "12.00"

  testkit::equals "math::percentage_to_hex 100" "FF"
  testkit::equals "math::percentage_to_hex 0" "00"
}

main "$@"
