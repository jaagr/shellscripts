#!/usr/bin/env bash
#
# Utility library for creating spinners
#   jaagr <c@rlberg.se>
#

# Style constants {{{

test '[post-pass:require-fn=spinner::get]'
declare -g -r SPINNER_STYLE_DOTS_1=("⣷" "⣯" "⣟" "⡿" "⢿" "⣻" "⣽" "⣾")
declare -g -r SPINNER_STYLE_DOTS_2=("⠁" "⠂" "⠄" "⡀" "⢀" "⠠" "⠐" "⠈")

declare -g -r SPINNER_STYLE_SPIN_1=("←" "↖" "↑" "↗" "→" "↘" "↓" "↙")
declare -g -r SPINNER_STYLE_SPIN_2=("b" "ᓂ" "q" "ᓄ")
declare -g -r SPINNER_STYLE_SPIN_3=("d" "ᓇ" "p" "ᓀ")
declare -g -r SPINNER_STYLE_SPIN_4=("|" "/" "—" "\\\\\\")
declare -g -r SPINNER_STYLE_SPIN_5=("x" "+")
declare -g -r SPINNER_STYLE_SPIN_6=("◰" "◳" "◲" "◱")
declare -g -r SPINNER_STYLE_SPIN_7=("◴" "◷" "◶" "◵")
declare -g -r SPINNER_STYLE_SPIN_8=("◐" "◓" "◑" "◒")
declare -g -r SPINNER_STYLE_SPIN_9=("⠂" "⠄" "⠠" "⠐")
declare -g -r SPINNER_STYLE_SPIN_10=("🕐" "🕑" "🕒" "🕓" "🕔" "🕕" "🕖" "🕗" "🕘" "🕙" "🕚" "🕛")
declare -g -r SPINNER_STYLE_SPIN_11=("🌕" "🌔" "🌓" "🌒" "🌑" "🌘" "🌗" "🌖")

declare -g -r SPINNER_STYLE_GROW_1=("|" "b" "O" "b")
declare -g -r SPINNER_STYLE_GROW_2=("_" "o" "O" "o")
declare -g -r SPINNER_STYLE_GROW_3=("." "o" "O" "@" "*" " ")
declare -g -r SPINNER_STYLE_GROW_4=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" "▂")
declare -g -r SPINNER_STYLE_GROW_5=("▉" "▊" "▋" "▌" "▍" "▎" "▏" "▎" "▍" "▌" "▋" "▊" "▉")
declare -g -r SPINNER_STYLE_GROW_6=(" " "▏" "▎" "▍" "▌" "▋" "▊" "▉" "▉" "█" "▉" "▊" "▋" "▌" "▍" "▎" "▏")

declare -g -r SPINNER_STYLE_MISC_1=("d" "|" "b" "|")
declare -g -r SPINNER_STYLE_MISC_2=("q" "|" "p" "|")
declare -g -r SPINNER_STYLE_MISC_3=("ᓂ" "—" "ᓄ" "—")
declare -g -r SPINNER_STYLE_MISC_4=("ᓇ" "—" "ᓀ" "—")
test '[/post-pass:require-fn]'

# }}}

function spinner::get
{
  # reference variables to names
  # passed in as arguments
  local -n output=$1 ; shift
  local -n index=$1 ; shift
  local -u -n style=SPINNER_STYLE_${1:-dots_1} ; shift

  output=${style[$((index % ${#style[@]}))]}
  index+=1
}

function spinner::print
{
  local buffer
  spinner::get buffer "$1" "$2"
  echo "$buffer"
}
