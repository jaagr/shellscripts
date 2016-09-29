#!/usr/bin/env bash

source bootstrap.sh

include utils/testkit.sh
include utils/algo.sh

bootstrap::finish

function main
{
  testkit::equals "algo::luhn 551001253" "6"
  testkit::equals "algo::luhn 6602020015" "0"
}

main "$@"
