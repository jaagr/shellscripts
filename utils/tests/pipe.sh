#!/usr/bin/env bash

source bootstrap.sh

include utils/testkit.sh
include utils/pipe.sh

bootstrap::finish

function main
{
  pipe::open

  pipe::push "value1"
  pipe::push "value2"
  pipe::push "value3"

  testkit::equals "pipe::peek 'tmp'; echo \$tmp" "value1"
  testkit::equals "pipe::peek 'tmp'; echo \$tmp" "value2"

  pipe::close

  testkit::equals "pipe::peek 'tmp'; echo \$tmp" ""

  pipe::open

  pipe::push "tail1"
  pipe::push "tail2"
  pipe::push "tail3"
  pipe::push "EOF"

  testkit::equals "tmp=\$(pipe::tail); echo \$tmp" "tail1 tail2 tail3"

  pipe::close
}

main "$@"
