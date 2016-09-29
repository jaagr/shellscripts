#!/usr/bin/env bash

source bootstrap.sh

include utils/ansi.sh
include utils/log/banner.sh
include utils/log/defer.sh

function main {
  [[ $1 == "pending" || $# -eq 0 ]] && {
    echo -e "[utils/log/pending.sh]\n"

    log::defer "Pending..." ; sleep 0.25
    log::defer::success

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure

    log::defer "Pending..." ; sleep 0.25
    log::defer::success "Success" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure "Failure" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::other "Replace message"
  }

  [[ $1 == "plain" || $# -eq 0 ]] && {
    [[ $# -eq 0 ]] && ansi::draw_line

    echo -e "[utils/log/format/plain.sh]\n"

    load utils/log/format/plain.sh

    log "Lorem ipsum dolor sit amet"
    log::debug "Lorem ipsum dolor sit amet"
    log::info "Lorem ipsum dolor sit amet"
    log::ok "Lorem ipsum dolor sit amet"
    log::warn "Lorem ipsum dolor sit amet"
    log::err "Lorem ipsum dolor sit amet"
    log::fatal "Lorem ipsum dolor sit amet"

    echo -e "\n[utils/log/pending.sh + utils/log/format/plain.sh]\n"

    log::defer "Pending..." ; sleep 0.25
    log::defer::success

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure

    log::defer "Pending..." ; sleep 0.25
    log::defer::success "Success" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure "Failure" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::other "Replace message"
  }

  [[ $1 == "tags" || $# -eq 0 ]] && {
    [[ $# -eq 0 ]] && ansi::draw_line

    echo -e "[utils/log/format/tags.sh]\n"

    load utils/log/format/tags.sh

    log "Lorem ipsum dolor sit amet"
    log::debug "Lorem ipsum dolor sit amet"
    log::info "Lorem ipsum dolor sit amet"
    log::ok "Lorem ipsum dolor sit amet"
    log::warn "Lorem ipsum dolor sit amet"
    log::err "Lorem ipsum dolor sit amet"
    log::fatal "Lorem ipsum dolor sit amet"

    echo -e "\n[utils/log/format/pending.sh + utils/log/format/tags.sh]\n"

    log::defer "Pending..." ; sleep 0.25
    log::defer::success

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure

    log::defer "Pending..." ; sleep 0.25
    log::defer::success "Success" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure "Failure" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::other "Message"
  }

  [[ $1 == "blocks" || $# -eq 0 ]] && {
    [[ $# -eq 0 ]] && ansi::draw_line

    echo -e "[utils/log/format/blocks.sh]\n"

    load utils/log/format/blocks.sh

    log "Lorem ipsum dolor sit amet"
    log::debug "Lorem ipsum dolor sit amet"
    log::info "Lorem ipsum dolor sit amet"
    log::ok "Lorem ipsum dolor sit amet"
    log::warn "Lorem ipsum dolor sit amet"
    log::err "Lorem ipsum dolor sit amet"
    log::fatal "Lorem ipsum dolor sit amet"

    echo -e "\n[utils/log/format/pending.sh + utils/log/format/blocks.sh]\n"

    log::defer "Pending..." ; sleep 0.25
    log::defer::success

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure

    log::defer "Pending..." ; sleep 0.25
    log::defer::success "Success" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure "Failure" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::other "Message"
  }

  [[ $1 == "icons" || $# -eq 0 ]] && {
    [[ $# -eq 0 ]] && ansi::draw_line

    echo -e "[utils/log/format/icons.sh]\n"

    load utils/log/format/icons.sh

    log "Lorem ipsum dolor sit amet"
    log::debug "Lorem ipsum dolor sit amet"
    log::info "Lorem ipsum dolor sit amet"
    log::ok "Lorem ipsum dolor sit amet"
    log::warn "Lorem ipsum dolor sit amet"
    log::err "Lorem ipsum dolor sit amet"
    log::fatal "Lorem ipsum dolor sit amet"

    echo -e "\n[utils/log/format/pending.sh + utils/log/format/icons.sh]\n"

    log::defer "Pending..." ; sleep 0.25
    log::defer::success

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure

    log::defer "Pending..." ; sleep 0.25
    log::defer::success "Success" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure "Failure" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::other "Message"
  }

  [[ $1 == "slim" || $# -eq 0 ]] && {
    [[ $# -eq 0 ]] && ansi::draw_line

    echo -e "[utils/log/format/slim.sh]\n"

    load utils/log/format/slim.sh

    log "Lorem ipsum dolor sit amet"
    log::debug "Lorem ipsum dolor sit amet"
    log::info "Lorem ipsum dolor sit amet"
    log::ok "Lorem ipsum dolor sit amet"
    log::warn "Lorem ipsum dolor sit amet"
    log::err "Lorem ipsum dolor sit amet"
    log::fatal "Lorem ipsum dolor sit amet"

    echo -e "\n[utils/log/format/pending.sh + utils/log/format/slim.sh]\n"

    log::defer "Pending..." ; sleep 0.25
    log::defer::success

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure

    log::defer "Pending..." ; sleep 0.25
    log::defer::success "Success" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::failure "Failure" "Lorem ipsum..."

    log::defer "Pending..." ; sleep 0.25
    log::defer::other "Message"
  }

  [[ $1 == "banner" || $# -eq 0 ]] && {
    [[ $# -eq 0 ]] && ansi::draw_line

    echo -e "[utils/log/banner.sh]\n"

    log::banner 13 "test odd 1"; echo
    log::banner 13 "test odd2"; echo
    log::banner 10 "test even1"; echo
    log::banner 10 "test even 2"; echo

    log::banner 30 " " "44;37;1"
    log::banner 30 "test" "44;37;1"
    log::banner 30 " " "44;37;1"
  }
}

main "$@"
