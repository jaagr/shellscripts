#!/usr/bin/env bash
#
# Utility funtions for the cli
#   jaagr <c@rlberg.se>
#

include utils/log.sh

test '[post-pass:require-fn=cli::parse]'
declare -gA __map=()
declare -gA __revmap=()
declare -gA __values=()
declare -gA __flags=()
declare -ga __positional=()

declare -gi CLI_FLAG_NONE=1
declare -gi CLI_FLAG_OPTVAL=2
declare -gi CLI_FLAG_REQVAL=4
test '[/post-pass:require-fn]'

function cli::define_flag # (short,long,helptext) ->
{
  local shortname="$1" ; shift
  local longname="$1" ; shift
  local helptext="$1" ; shift
  local -i flags=${1:-$CLI_FLAG_NONE} ; shift
  IFS="+"
  __map[$longname]="$flags+$shortname+$longname+${helptext//+/\\+}"
  __revmap[$shortname]=$longname
}

function cli::define_optflag
{
  echo TODO
}

function cli::define_arg
{
  echo TODO
}

function cli::define_optarg
{
  echo TODO
}

function cli::flag
{
  [[ "${__flags[$1]}" == "1" ]]
}

function cli::value
{
  echo "${__values[$1]}"
}

function cli::get_positional
{
  if [[ $# -eq 0 ]]; then
    echo "${__positional[@]}"
  elif [[ ${#__positional[@]} -ge $1 ]]; then
    echo "${__positional[$1]}"
  fi
}

function cli::parse
{
  local -a map_entry
  local -i flags
  local value

  while [[ $# -gt 0 ]]
  do
    unset value

    if [[ ${1:0:1} != "-" ]]; then
      __positional+=("$1")
      shift
      continue
    elif [[ ${#__map[${1%%=*}]} -gt 0 ]]; then
      map_entry=(${__map[${1%%=*}][@]})
      value="${1#*=}"
      if [[ ${#value} -eq ${#1} ]]; then
        unset value
      fi
      shiftcount=1

    elif [[ ${#__revmap[$1]} -gt 0 ]]; then
      map_entry=(${__map[${__revmap[$1]}][@]})

      if [[ $# -gt 1 ]] && [[ ${2:0:1} != "-" ]]; then
        value="$2"
        shiftcount=2
      elif [[ $# -gt 1 ]] && [[ ${2:0:1} == "-" ]]; then
        shiftcount=1
        unset value
      fi

    else
      log::err "Unrecognized argument '$1'" ; exit 125
    fi

    local -n shortname="map_entry[1]"
    local -n longname="map_entry[2]"
    local -n flags_ref="map_entry[0]"

    let flags=$flags_ref

    if (( (flags & CLI_FLAG_NONE) == CLI_FLAG_NONE )); then
      if [[ "$value" ]] && [[ $shiftcount -gt 1 ]]; then
        let shiftcount--;
        unset value
      fi
      __flags[$longname]=1
    else

      if (( (flags & CLI_FLAG_REQVAL) == CLI_FLAG_REQVAL )) && ! [[ "$value" ]]; then
        log::err "Option '$longname' requires an argument..." ; exit 125
      fi

      if [[ ${#__values[$longname]} -gt 0 ]]; then
        log::err "Option '$longname' defined more than once..." ; exit 125
      fi

      __values[$longname]=$value
    fi

    shift $shiftcount
  done

  # for _ in "${!__values[@]}"; do
  #   echo "$_ == ${__values[$_]}"
  # done

  # for _ in "${!__flags[@]}"; do
  #   echo "$_ == ${__flags[$_]}"
  # done

  # for (( iter=0; iter<${#__positional[@]}; ++iter )); do
  #   echo "${__positional[$iter]}"
  # done
}

function cli::usage
{
  local -a map_entry
  local i maxlen=0 len=0

  for _ in "${!__map[@]}"; do
    map_entry=(${__map[$_][@]})
    let len=${#map_entry[1]}+${#map_entry[2]}
    maxlen=$((len>maxlen?len:maxlen))
  done
  let maxlen+=2

  printf "%s\n\n" "Usage: ${BASH_SOURCE[1]##*/} ${1:-[OPTION...]}"
  for _ in "${!__map[@]}"; do
    map_entry=(${__map[$_][@]})
    printf "  %s, %s" "${map_entry[1]}" "${map_entry[2]}"
    printf "%*s %s\n" $(( maxlen - ${#map_entry[1]} - ${#map_entry[2]} )) " " "${map_entry[3]}"
  done
}

function cli::usage_from_commentblock
{
  [[ -n "$1" ]] && script="$1" || script="$0"

  local script_name
  script_name=$(basename "$script")

  local synopsis='false'
  local options='false'

  while read -r line
  do
    # Break at first non-comment line
    [[ "${line:0:1}" = '#' ]] || break

    [[ "${line##* }" == "Synopsis:" ]] && {
      synopsis='true'
      continue
    }
    [[ "${line##* }" == "Options:" ]] && {
      printf "\n"
      options='true'
      continue
    }

    if $synopsis; then
      line=${line:4}
      line=${line//\$\{SCRIPT_NAME\} /}
      line=${line//\$0 /}
      echo "Usage: $script_name $line"
      synopsis='false'
      continue
    fi

    if $options; then
      [[ "${line:0:4}" != "#   " ]] && {
        printf "\n"
        options='false'
        continue
      }

      echo "${line:1}"
    fi
  done < "$script"
}
