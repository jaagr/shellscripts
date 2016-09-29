#!/usr/bin/env bash

source bootstrap.sh

include utils/testkit.sh
include utils/json.sh

bootstrap::finish

function main
{
  json=$(cat <<-EOF
{
  \"x\": {
    \"real\": 1844,
    \"fake\": -5
  },
  \"y\": 547,
  \"width\": 677,
  \"height\": 504
}
EOF
)
  json=${json//  /}
  testkit::equals "json::get_value \"$json\" \"x.fake\"" "-5" | tr -d '\\\n'
  echo
  testkit::equals "json::get_value \"$json\" \"width\"" "677" | tr -d '\\\n'
  echo
}

main "$@"
