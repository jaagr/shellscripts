#!/usr/bin/env bash
#
# Lorem ipsum dolor sit amet...
#   jaagr <c@rlberg.se>
#

source bootstrap.sh

include utils/log.sh
include utils/cli2.sh

bootstrap::finish

cli::define_flag -h --help  "Print this help text"
cli::define_flag -f --force "..."

function main {
  cli::parse "$@"

  if cli::flag --help; then
    cli::usage "[opts...] arg"; exit
  fi
}

main "$@"
