#!/usr/bin/env bash

source bootstrap.sh

include utils/testkit.sh
include utils/str.sh

bootstrap::finish

function main
{
  testkit::equals "str::upper abc" "ABC"
  testkit::equals "str::upper 178abbb%" "178ABBB%"

  testkit::equals "str::lower ABC" "abc"
  testkit::equals "str::lower 178ABBB%" "178abbb%"

  testkit::equals 'echo -e "1\n2" | str::shift_right 2' "$(echo -e "  1\n  2")"
  testkit::equals 'echo -e "1\n2\n3" | str::shift_right 3 "a"' "$(echo -e "aaa1\naaa2\naaa3")"
}

main "$@"
