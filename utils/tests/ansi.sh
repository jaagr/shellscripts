#!/usr/bin/env bash

source bootstrap.sh

include utils/testkit.sh
include utils/ansi.sh

bootstrap::finish

# force ansi support
function ansi::check_support {
  return 0
}

function main
{
  testkit::equals "ansi::colorize 31 foobar" "$(echo -ne "\033[31mfoobar\033[0m")"
  testkit::equals "ansi::colorize 31 foo bar" "$(echo -ne "\033[31mfoo bar\033[0m")"
  testkit::equals "ansi::bold foobar" "$(echo -ne "\033[1mfoobar\033[0m")"
  testkit::equals "ansi::bold foo bar" "$(echo -ne "\033[1mfoo bar\033[0m")"
  testkit::equals "ansi::italic foobar" "$(echo -ne "\033[3mfoobar\033[0m")"
  testkit::equals "ansi::italic foo bar" "$(echo -ne "\033[3mfoo bar\033[0m")"
  testkit::equals "ansi::conceal foobar" "$(echo -ne "\033[8mfoobar\033[0m")"
  testkit::equals "ansi::conceal foo bar" "$(echo -ne "\033[8mfoo bar\033[0m")"
  testkit::equals "ansi::strikethrough foobar" "$(echo -ne "\033[9mfoobar\033[0m")"
  testkit::equals "ansi::strikethrough foo bar" "$(echo -ne "\033[9mfoo bar\033[0m")"
}

main "$@"
