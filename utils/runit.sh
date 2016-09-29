#!/bin/bash

include utils/log.sh
include utils/log/defer.sh
include utils/pipe.sh

# TODO: remove
DEFAULT_RUNSVDIR_PREFIX=/var/service
DEFAULT_CONTAINER_ROOT=/etc/sv

function runit::test_user_container
{
  log::defer "Checking if user container is running..."

  if ! sudo sv status "${DEFAULT_RUNSVDIR_PREFIX}/usercontainer-$(whoami)" >/dev/null 2>&1; then
    log::defer::failure; return 1
  fi

  log::defer::success
}

function runit::is_service
{
  local service=$1 ; shift
  local svroot

  [[ $# -gt 0 ]] && {
    svroot=$service
    service=$1
  }

  [[ "$service" ]] || {
    log::err "Service not specified"; exit 1
  }

  [[ "$service" ]] && [[ -e "${svroot:-$DEFAULT_CONTAINER_ROOT}/${service}" ]]
}

function runit::validate
{
  local service="$1" ; shift
  local svroot

  [[ $# -gt 0 ]] && {
    svroot=$service
    service=$1
  }

  runit::is_service "${svroot:-$DEFAULT_CONTAINER_ROOT}" "$service" || {
    log::err "Service \"${service}\" does not exist"; exit 2
  }
}
