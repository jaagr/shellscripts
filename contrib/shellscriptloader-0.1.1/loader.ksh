#!/usr/bin/env ksh


# ----------------------------------------------------------------------

# loader.ksh
#
# This script implements Shell Script Loader for ksh; both the original
# (KornShell 93+) and the public domain (PD KSH) Korn shell.
#
# Please see loader.txt for more info on how to use this script.
#
# This script complies with the Requiring Specifications of
# Shell Script Loader version 0 (RS0)
#
# Version: 0.1
#
# Author: konsolebox
# Copyright Free / Public Domain
# Aug. 29, 2009 (Last Updated 2011/04/08)

# Limitations of Shell Script Loader in PD KSH:
#
# In PD KSH (not the Ksh 93+), typeset declarations inside functions
# always make variables only available within the encapsulating function
# therefore scripts that have typeset declarations that are meant to
# create global variables when called within a loader function like
# include() will only have visibility inside include().
#
# Array indices in PD KSH are currently limited to the range of 0
# through 1023 but this value is big enough for the list of search paths
# and for the call stack.

# ----------------------------------------------------------------------


if [ "$LOADER_ACTIVE" = true ]; then
	echo "loader: loader cannot be loaded twice."
	exit 1
fi
if [ -n "$KSH_VERSION" ]; then
	LOADER_KSH_VERSION=1
elif
	( eval 'test -n "${.sh.version}" && exit 10'; ) >/dev/null 2>&1
	[ "$?" -eq 10 ]
then
	LOADER_KSH_VERSION=0
elif [ "$ZSH_NAME" = ksh ]; then
	echo "loader: emulated ksh from zsh does not work with this script."
	exit 1
else
	echo "loader: ksh is needed to run this script."
	exit 1
fi


#### PUBLIC VARIABLES ####

LOADER_ACTIVE=true
LOADER_RS=0
LOADER_VERSION=0.1


#### PRIVATE VARIABLES ####

set -A LOADER_CS
set -A LOADER_PATHS
LOADER_CS_I=0


#### PUBLIC FUNCTIONS ####

load() {
	[[ $# -eq 0 ]] && loader_fail "function called with no argument." load

	case "$1" in
	'')
		loader_fail "file expression cannot be null." load "$@"
		;;
	/*|./*|../*)
		if [[ -f $1 ]]; then
			loader_getabspath "$1"

			[[ -r $__ ]] || loader_fail "file not readable: $__" load "$@"

			shift
			loader_load "$@"

			return
		fi
		;;
	*)
		for __ in "${LOADER_PATHS[@]}"; do
			[[ -f $__/$1 ]] || continue

			loader_getabspath "$__/$1"

			[[ -r $__ ]] || loader_fail "found file not readable: $__" load "$@"

			loader_flag_ "$1"

			shift
			loader_load "$@"

			return
		done
		;;
	esac

	loader_fail "file not found: $1" load "$@"
}

include() {
	[[ $# -eq 0 ]] && loader_fail "function called with no argument." include

	case "$1" in
	'')
		loader_fail "file expression cannot be null." include "$@"
		;;
	/*|./*|../*)
		loader_getabspath "$1"

		loader_flagged "$__" && \
			return

		if [[ -f $__ ]]; then
			[[ -r $__ ]] || loader_fail "file not readable: $__" include "$@"

			shift
			loader_load "$@"

			return
		fi
		;;
	*)
		loader_flagged "$1" && \
			return

		for __ in "${LOADER_PATHS[@]}"; do
			loader_getabspath "$__/$1"

			if loader_flagged "$__"; then
				loader_flag_ "$1"

				return
			elif [[ -f $__ ]]; then
				[[ -r $__ ]] || loader_fail "found file not readable: $__" include "$@"

				loader_flag_ "$1"

				shift
				loader_load "$@"

				return
			fi
		done
		;;
	esac

	loader_fail "file not found: $1" include "$@"
}

call() {
	[[ $# -eq 0 ]] && loader_fail "function called with no argument." call

	case "$1" in
	'')
		loader_fail "file expression cannot be null." call "$@"
		;;
	/*|./*|../*)
		if [[ -f $1 ]]; then
			loader_getabspath "$1"

			[[ -r $__ ]] || loader_fail "file not readable: $__" call "$@"

			(
				shift
				loader_load "$@"
			)

			return
		fi
		;;
	*)
		for __ in "${LOADER_PATHS[@]}"; do
			[[ -f $__/$1 ]] || continue

			loader_getabspath "$__/$1"

			[[ -r $__ ]] || loader_fail "found file not readable: $__" call "$@"

			(
				loader_flag_ "$1"

				shift
				loader_load "$@"
			)

			return
		done
		;;
	esac

	loader_fail "file not found: $1" call "$@"
}

loader_addpath() {
	for __ in "$@"; do
		[[ -d $__ ]] || loader_fail "directory not found: $__" loader_addpath "$@"
		[[ -x $__ ]] || loader_fail "directory not accessible: $__" loader_addpath "$@"
		[[ -r $__ ]] || loader_fail "directory not searchable: $__" loader_addpath "$@"
		loader_getabspath_ "$__/."
		loader_addpath_ "$__"
	done
}

loader_flag() {
	[[ $# -eq 1 ]] || loader_fail "function requires a single argument." loader_flag "$@"
	loader_getabspath "$1"
	loader_flag_ "$__"
}

loader_reset() {
	if [[ $# -eq 0 ]]; then
		loader_resetflags
		loader_resetpaths
	elif [[ $1 = flags ]]; then
		loader_resetflags
	elif [[ $1 = paths ]]; then
		loader_resetpaths
	else
		loader_fail "invalid argument: $1" loader_reset "$@"
	fi
}

loader_finish() {
	LOADER_ACTIVE=false

	loader_unsetvars

	unset \
		load \
		include \
		call \
		loader_addpath \
		loader_addpath_ \
		loader_fail \
		loader_finish \
		loader_flag \
		loader_flag_ \
		loader_flagged \
		loader_getabspath \
		loader_getabspath_ \
		loader_load \
		loader_load_ \
		loader_reset \
		loader_unsetvars \
		LOADER_CS \
		LOADER_CS_I \
		LOADER_KSH_VERSION \
		LOADER_PATHS
}


#### PRIVATE FUNCTIONS ####

loader_addpath_() {
	for __ in "${LOADER_PATHS[@]}"; do
		[[ $1 = $__ ]] && \
			return
	done

	LOADER_PATHS[${#LOADER_PATHS[@]}]=$1
}

loader_load() {
	loader_flag_ "$__"

	LOADER_CS[++LOADER_CS_I]=$__

	loader_load_ "$@"

	__=$?

	LOADER_CS[LOADER_CS_I--]=

	return "$__"
}

loader_load_() {
	. "$__"
}

loader_getabspath() {
	case "$1" in
	.|'')
		case "$PWD" in
		/)
			__=/.
			;;
		*)
			__=${PWD%/}
			;;
		esac
		;;
	..|../*|*/..|*/../*|./*|*/.|*/./*|*//*)
		loader_getabspath_ "$1"
		;;
	/*)
		__=$1
		;;
	*)
		__=${PWD%/}/$1
		;;
	esac
}

loader_fail() {
	typeset MESSAGE FUNC A I

	MESSAGE=$1 FUNC=$2
	shift 2

	{
		echo "loader: ${FUNC}(): ${MESSAGE}"
		echo

		echo "  current scope:"
		if [[ LOADER_CS_I -gt 0 ]]; then
			echo "    ${LOADER_CS[LOADER_CS_I]}"
		else
			echo "    (main)"
		fi
		echo

		if [[ $# -gt 0 ]]; then
			echo "  command:"
			echo -n "    $FUNC"
			for A; do
				echo -n " \"$A\""
			done
			echo
			echo
		fi

		if [[ LOADER_CS_I -gt 0 ]]; then
			echo "  call stack:"
			echo "    (main)"
			I=1
			while [[ I -le LOADER_CS_I ]]; do
				echo "    -> ${LOADER_CS[I]}"
				(( ++I ))
			done
			echo
		fi

		echo "  search paths:"
		if [[ ${#LOADER_PATHS[@]} -gt 0 ]]; then
			for A in "${LOADER_PATHS[@]}"; do
				echo "    $A"
			done
		else
			echo "    (empty)"
		fi
		echo

		echo "  working directory:"
		echo "    $PWD"
		echo
	} >&2

	exit 1
}


#### VERSION DEPENDENT FUNCTIONS AND VARIABLES ####

if [[ $LOADER_KSH_VERSION = 0 ]]; then
	eval "
		LOADER_FLAGS=([.]=.)
		LOADER_PATHS_FLAGS=([.]=.)

		loader_addpath_() {
			if [[ -z \${LOADER_PATHS_FLAGS[\$1]} ]]; then
				LOADER_PATHS[\${#LOADER_PATHS[@]}]=\$1
				LOADER_PATHS_FLAGS[\$1]=.
			fi
		}

		loader_flag_() {
			LOADER_FLAGS[\$1]=.
		}

		loader_flagged() {
			[[ -n \${LOADER_FLAGS[\$1]} ]]
		}

		loader_resetflags() {
			LOADER_FLAGS=()
		}

		loader_resetpaths() {
			set -A LOADER_PATHS
			LOADER_PATHS_FLAGS=()
		}

		loader_unsetvars() {
			unset LOADER_FLAGS LOADER_PATHS_FLAGS
		}
	"

	if
		eval "
			__=.
			read __ <<< \"\$__\"
			[[ \$__ = '\".\"' ]]
		"
	then
		eval "
			function loader_getabspath_ {
				typeset T1 T2
				typeset -i I=0
				typeset IFS=/ A

				case \"\$1\" in
				/*)
					read -r -A T1 <<< \$1
					;;
				*)
					read -r -A T1 <<< \$PWD/\$1
					;;
				esac

				set -A T2

				for A in \"\${T1[@]}\"; do
					case \"\$A\" in
					..)
						[[ I -ne 0 ]] && unset T2\\[--I\\]
						continue
						;;
					.|'')
						continue
						;;
					esac

					T2[I++]=\$A
				done

				case \"\$1\" in
				*/)
					[[ I -ne 0 ]] && __=\"/\${T2[*]}/\" || __=/
					;;
				*)
					[[ I -ne 0 ]] && __=\"/\${T2[*]}\" || __=/.
					;;
				esac
			}
		"
	else
		eval "
			function loader_getabspath_ {
				typeset T1 T2
				typeset -i I=0
				typeset IFS=/ A

				case \"\$1\" in
				/*)
					read -r -A T1 <<< \"\$1\"
					;;
				*)
					read -r -A T1 <<< \"\$PWD/\$1\"
					;;
				esac

				set -A T2

				for A in \"\${T1[@]}\"; do
					case \"\$A\" in
					..)
						[[ I -ne 0 ]] && unset T2\\[--I\\]
						continue
						;;
					.|'')
						continue
						;;
					esac

					T2[I++]=\$A
				done

				case \"\$1\" in
				*/)
					[[ I -ne 0 ]] && __=\"/\${T2[*]}/\" || __=/
					;;
				*)
					[[ I -ne 0 ]] && __=\"/\${T2[*]}\" || __=/.
					;;
				esac
			}
		"
	fi
else
	loader_addpath_() {
		for __ in "${LOADER_PATHS[@]}"; do
			[[ $1 = "$__" ]] && \
				return
		done

		LOADER_PATHS[${#LOADER_PATHS[@]}]=$1
	}

	loader_flag_() {
		eval "LOADER_FLAGS_$(echo "$1" | sed 's/\./_dt_/g; s/\//_sl_/g; s/ /_sp_/g; s/[^[:alnum:]_]/_ot_/g')=."
	}

	loader_flagged() {
		eval "[[ -n \$LOADER_FLAGS_$(echo "$1" | sed 's/\./_dt_/g; s/\//_sl_/g; s/ /_sp_/g; s/[^[:alnum:]_]/_ot_/g') ]]"
	}

	loader_getabspath_() {
		typeset A T IFS=/ TOKENS I=0 J=0

		A=${1%/}

		if [[ -n $A ]]; then
			while :; do
				T=${A%%/*}

				case "$T" in
				..)
					if [[ I -gt 0 ]]; then
						unset TOKENS\[--I\]
					else
						(( ++J ))
					fi
					;;
				.|'')
					;;
				*)
					TOKENS[I++]=$T
					;;
				esac

				case "$A" in
				*/*)
					A=${A#*/}
					;;
				*)
					break
					;;
				esac
			done
		fi

		__="/${TOKENS[*]}"

		if [[ $1 != /* ]]; then
			A=${PWD%/}

			while [[ J -gt 0 && -n $A ]]; do
				A=${A%/*}
				(( --J ))
			done

			[[ -n $A ]] && __=$A${__%/}
		fi

		if [[ $__ = / ]]; then
			[[ $1 != */ ]] && __=/.
		elif [[ $1 == */ ]]; then
			__=$__/
		fi
	}

	loader_resetflags() {
		unset $(set | grep -a ^LOADER_FLAGS_ | cut -f 1 -d =)
	}

	loader_resetpaths() {
		set -A LOADER_PATHS
	}

	loader_unsetvars() {
		loader_resetflags
	}
fi


# ----------------------------------------------------------------------

# * In some if not all versions of ksh, "${@:X[:Y]}" always presents a
#   single null string if no positional parameter is matched.
#
# * In some versions of ksh, 'read <<< "$VAR"' includes '"' in the
#   string.
#
# * Using 'set -- $VAR' to split strings inside variables will sometimes
#   yield different strings if one of the strings contain globs
#   characters like *, ? and the brackets [ and ] that are also valid
#   characters in filenames.
#
# * Changing the IFS causes buggy behaviors in PD KSH.

# ----------------------------------------------------------------------
