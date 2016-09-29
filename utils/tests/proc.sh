#!/usr/bin/env bash

source bootstrap.sh

include utils/testkit.sh
include utils/proc.sh

bootstrap::finish

function main
{
  proc::run_and_wait "sleep 3 ; echo"
}

main "$@"
