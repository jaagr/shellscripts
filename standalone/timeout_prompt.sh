#!/usr/bin/env bash

# TODO: Replace the prompting with:
# > select choice in OPT1 OPT2 OPT3

require::set_timer(){
  timeout="$1" ; shift

  [[ -n "$timeout_pid" ]] && kill "$timeout_pid"

  { sleep "$timeout"
    kill -SIGUSR1 0
  } & timeout_pid=$!
}

require::prompt(){
  local text="$1" ; shift
  local choices=("$@") choice

  echo "Enter a valid choice (${choices[*]}):"
  read -r input

  [[ -n $timeout_pid ]] && kill "$timeout_pid"

  for choice in "${choices[@]}"; do
    if [[ "$input" == "$choice" ]]; then
      result="$choice"; return
    fi
  done

  [[ $input ]] && echo -e "\"$input\" is not a valid choice.\n"

  [[ -n "$timeout" ]] && require::set_timer "$timeout"

  require::prompt "$text" "${choices[@]}"
}

main() {
  trap 'return' SIGUSR1

  require::set_timer 3
  require::prompt "title" "A" "B" "C"

  if [[ -z "$result" ]]; then
    echo -e "Timeout"; exit
  fi

  echo "Result: $result"
}

main "$@" 2>/dev/null
