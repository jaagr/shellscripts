#!/usr/bin/env bash
#
# Utility funtions for the cli
#   jaagr <c@rlberg.se>
#

include utils/log.sh

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

function cli::unrecognized_option
{
  log::err "Unrecognized option '$1'"
  log "Try $(basename "$0") --help for more information."
  exit 125
}

function cli::get_argument_value
{
  if [[ ${1:0:2} == "--" ]]; then
    echo "$1" | sed -rn 's/^--[^=\ ]*=([^\ ]*)$/\1/p' ; exit 1
  elif [[ ${#1} -eq 2 ]]; then
    echo "$2" ; exit 0
  else
    exit 1
  fi
}
