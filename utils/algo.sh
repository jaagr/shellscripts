#!/usr/bin/env bash

function algo::luhn {
  local seq="$1" ; shift
  local val ret map i j

  for (( i=1 ; i<=${#seq} ; i+=1 )); do
    j="${seq:$i-1:1}"
    val=$(( j * ( i % 2 + 1 ) ));
    map="${map}${val}"
  done

  ret=$(echo "${map}" | sed -nr 's/(.)/\1+/gp' | sed -nr 's/^(.*)\+$/\1/gp' )

  if [[ "${#seq}" -eq 9 ]]; then
    echo "$(( 10 - ( ret % 10 )))"
  else
    echo "$(( ret % 10 ))"
  fi
}
