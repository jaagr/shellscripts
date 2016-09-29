#!/usr/bin/env gawk -f

# ----------------------------------------------------------------------

# compiler.gawk
#
# This script is a prototype compiler and attempts to comply with the
# Requiring Specifications of Shell Script Loader version 0 (RS0) and
# derived or similar versions like RS0X, RS0L and RS0S.
#
# The script also still have some limitations with script runtime
# emulation like not yet being able to recurse to call() and callx()
# functions.  We know that call() summons file(s) inside a new
# environment or subshell so implementing it needs very careful planning
# and may cause heavy overhaul to the whole code.  One of the difficult
# tasks with respect to this is knowing the proper way to handle code on
# files that are called after a call since virtually it should run to a
# new subshell and therefore things like errors (may it be syntactical
# or not) should be separated from the handling of the parent script.
# One of the solutions I currently thought on how to make this work is
# by using double-indexed associative arrays on the virtual stacks that
# increments everytime a new context is entered.  That may be the a good
# solution but it may also cause a slight minus on runtime speed.  With
# relation to the handling of errors, I probably can also solve it by
# adding new options that may tell the compiler if it should bail out if
# an error is found in a sub-context or not.  Timewise though, making
# these changes will probably beat a lot of it and it's also not a
# guarantee that these big changes will yield a stable code soon.  Also,
# thinking that the current code is already about 97.0 to 99.5% stable
# (as tests shows), I thought that it's better if I just make a new
# release first than immediately starting to apply new changes to it.
#
# Hopefully, full support for Shell Script Loader may be finished when
# RSO is finalized or when the its first stable version is released.
#
# Aside from the functions, there are also additional directives that
# are recognized by this compiler.  These would also work in uppercase
# format.
#
# (a) #begin_skip_block - #end_skip_block /
#     #begin_compiler_skip - #end_compiler_skip
#
#     Specifies that text will not be included from compilation.
#
# (a) #begin_no_parse_block - #end_no_parse_block /
#     #begin_compiler_no_parse - #end_compiler_no_parse
#
#     Specifies that text will be include but not parsed or will just be
#     treated as plain text.
#
# (c) #begin_no_indent_block - #end_no_indent_block /
#     #begin_compiler_no_indent - #end_compiler_no_indent
#
#     Specifies that text will not be indented when included inside call
#     functions.
#
# Here are some scripts that's compatible with the compiler:
#
# ----------------------------------------
#
#  #!/bin/sh
#
#  #begin_skip_block
#  if [ "$LOADER_ACTIVE" = true ]; then
#      # Shell Script Loader was not yet loaded from any previous
#      # context. We'll load it here. The conditional expression above
#      # is only optional and may be excluded if the script is intended
#      # not to be called from call() or callx().
#      . "<some path to>/loader.sh"
#  else
#  #end_skip_block
#      # Include a command that will prevent using flags if this script
#      # is called with call() or callx(). If the compiler sees this
#      # line, it should also reset the flags for this context but it's
#      # currently not yet supported. This is also just optional and
#      # also depends on the intended on usage of the script.
#      loader_reset
#  #begin_skip_block
#  fi
#  #end_skip_block
#
#  # Add paths, this block may also be quoted with #begin_skip_block
#  # if the paths are intended to be added using the '--addpath' option
#  # of the compiler.
#  loader_addpath "<path1>" "<path2>"
#
#  # Since this is the main script, flag it. Just optional.
#  loader_flag "<path to this script>"
#
#  ....
#
# ----------------------------------------
#
#  #!/bin/sh
#
#  # Simpler and less confusing version. This script is intended to be
#  # not included with any previous loader commands.
#
#  #begin_skip_block
#  . "<some path to>/loader.sh"
#  #end_skip_block
#
#  loader_addpath "<path1>" "<path2>"
#
#  #optional
#  loader_flag "<path to this script>"
#
#  ....
#
# ----------------------------------------
#
# There's also a cleaner solution where you can just use two different
# scripts like start.sh and main.sh where start.sh is the starter script
# that loads Shell Script Loader and adds paths; and main.sh is the main
# script that also loads co-shell-scripts.  The starter script will not
# be specified during compile, it will only be called when the script is
# to run in the shell.  The main script will be the only one that will
# be specified during compile.  The paths also can just be specified
# with the option '--addpath' of this compiler.
#
# To know some more info about using this script, run it with the option
# '--usage' or '--help'.
#
# Version: 0.WP20141212 ( Working Prototype 2014/12/12
#                         for RS0, RS0X, RS0L and RS0S )
#
# Author: konsolebox
# Copyright Free / Public Domain
# Aug. 29, 2009 (Last Updated 2014/12/12)

# ----------------------------------------------------------------------


# Global Constants and Variables

function GLOBALS() {

	compiler_version = "0.WP20141212"

	compiler_default_output    = "/dev/stdout"
	compiler_calls_obj_file    = "compiler.calls.obj"
	compiler_main_obj_file     = "compiler.main.obj"
	compiler_complete_obj_file = "compiler.comp.obj"
#	compiler_temp_file         = "compiler.temp"
	compiler_temp_dir          = ""
	compiler_no_info           = 0
	compiler_no_indent         = 0
	compiler_debug_mode        = 0
	compiler_deprecated_mode   = 0
	compiler_extended          = 0

#	compiler_calls_funcnames[]
#	compiler_calls_groupcallseeds[]
#	compiler_calls_hashes[]
#	compiler_flags[]
#	compiler_keywords[]
	compiler_ignoreaddpaths = 0
	compiler_ignoreresets = 0
#	compiler_make_hash_ctable[]
#	compiler_make_hash_default_hash_length
#	compiler_make_hash_itable[]
#	compiler_paths[]
	compiler_paths_count = 0
#	compiler_paths_flags[]
	compiler_walk_current_file = ""
	compiler_walk_current_line = ""
	compiler_walk_current_line_number = 0
	compiler_walk_current_no_indent = 0
	compiler_walk_current_no_indent_start = 0
#	compiler_walk_stack_file[]
	compiler_walk_stack_i = 0
#	compiler_walk_stack_line[]
#	compiler_walk_stack_line_number[]

}


# Main Function

function compiler \
( \
\
	a, abs, b, i, files, files_count, header_file, output_file, shell, \
	sed_args,  strip, strip_comments, strip_blank_lines, \
	strip_extra_blank_lines,  strip_leading_spaces, \
	strip_trailing_comments, strip_trailing_spaces, use_sed \
)
{
	compiler_log_debug("compiler() [" ARGS "]")

	# Get current working directory.

	compiler_wd = compiler_get_working_dir()

	if (compiler_wd == "")
		compiler_log_failure("Unable to get path of current working directory.")

	# Parse command-line.

	for (i = 1; i < ARGC; ++i) {
		a = ARGV[i]

		if (a == "") {
			compiler_log_failure("One of the arguments is empty.")
		} else if (a == "-a" || a == "--addpath") {
			b = ARGV[++i]

			if (i == ARGC || length(b) == 0)
				compiler_log_failure("This option requires an argument: " a)

			if (! compiler_test("-d", b))
				compiler_log_failure("Directory not found:" b)

			compiler_addpath(b)
		} else if (a == "--debug") {
			compiler_debug_mode = 1
		} else if (a == "--deprecated") {
			compiler_deprecated_mode = 1
		} else if (a == "-x" || a == "--extended") {
			compiler_extended = 1
		} else if (a == "-h" || a == "--help" || a == "--usage") {
			compiler_show_info_and_usage()
			exit(1)
		} else if (a == "-H" || a == "--header") {
			b = ARGV[++i]

			if (i == ARGC || length(b) == 0)
				compiler_log_failure("This option requires an argument: " a)

			if (! compiler_test("-f", b))
				compiler_log_failure("Header file not found: " b)

			header_file = b
		} else if (a == "-ia" || a == "--ignore-addpaths") {
			compiler_ignoreaddpaths = 1
		} else if (a == "-ir" || a == "--ignore-resets") {
			compiler_ignoreresets = 1
		} else if (a == "-n" || a == "--no-info") {
			compiler_no_info = 1
		} else if (a == "-ni" || a == "--no-indent") {
			compiler_no_indent = 1
		} else if (a == "-o" || a == "--output") {
			if (length(output_file))
				compiler_log_failure("Output file should not be specified twice.")

			b = ARGV[++i]

			if (i == ARGC || length(b) == 0)
				compiler_log_failure("This option requires an argument: " a)

			output_file = b
		} else if (a == "-O") {
			compiler_no_info = 1
			strip = 1
			strip_comments = 1
			strip_extra_blank_lines = 1
			strip_trailing_spaces = 1
		} else if (a == "--RS0") {
			# default always; just for reference
			compiler_deprecated_mode = 0
			compiler_extended = 0
		} else if (a == "--RS0X") {
			compiler_deprecated_mode = 0
			compiler_extended = 1
		} else if (a == "--RS0L") {
			compiler_deprecated_mode = 1
			compiler_extended = 0
		} else if (a == "--RS0S") {
			compiler_deprecated_mode = 1
			compiler_extended = 1
		} else if (a == "--sed") {
			use_sed = 1
		} else if (a == "-s" || a == "--shell") {
			b = ARGV[++i]

			if (i == ARGC || length(b) == 0)
				compiler_log_failure("This option requires an argument: " a)

			shell = b
		} else if (a == "--strip-bl") {
			strip = 1
			strip_blank_lines = 1
		} else if (a == "--strip-c") {
			strip = 1
			strip_comments = 1
		} else if (a == "--strip-ebl") {
			strip = 1
			strip_extra_blank_lines = 1
		} else if (a == "--strip-ls") {
			strip = 1
			strip_leading_spaces = 1
		} else if (a == "--strip-tc") {
			strip = 1
			strip_trailing_comments = 1
		} else if (a == "--strip-ts") {
			strip = 1
			strip_trailing_spaces = 1
		} else if (a == "--strip-all") {
			strip = 1
			strip_blank_lines = 1
			strip_comments = 1
			strip_leading_spaces = 1
			strip_trailing_comments = 1
			strip_trailing_spaces = 1
		} else if (a == "--strip-all-safe") {
			strip = 1
			strip_comments = 1
			strip_extra_blank_lines = 1
			strip_trailing_spaces = 1
		} else if (a == "--tempdir") {
			b = ARGV[++i]

			if (i == ARGC || length(b) == 0)
				compiler_log_failure("This option requires an argument: " a)

			if (! compiler_test("-d", b))
				compiler_log_failure("Directory not found:" b)

			compiler_temp_dir = b
		} else if (a == "-V" || a == "--version") {
			compiler_show_version_info()
			exit(1)
		} else if (compiler_test("-f", a)) {
			files[files_count++] = a
		} else if (compiler_test("-d", a)) {
			compiler_log_failure("Argument is a directory and not a file: " a)
		} else if (a ~ /-.*/) {
			compiler_log_failure("Invalid option: " a)
		} else {
			compiler_log_failure("Invalid argument or file not found: " a)
		}
	}

	# Checks and Initializations

	if (files_count == 0)
		compiler_log_failure("No input file was entered.")

	if (length(output_file) == 0)
		output_file = compiler_default_output

	if (output_file != "/dev/stdout" && output_file != "/dev/stderr")
		if (! compiler_truncate_file(output_file))
			compiler_log_failure("Unable to truncate output file \"" output_file "\".")

	if (compiler_temp_dir) {
		compiler_main_obj_file = compiler_getabspath(compiler_temp_dir "/") compiler_main_obj_file
		compiler_calls_obj_file = compiler_getabspath(compiler_temp_dir "/") compiler_calls_obj_file
		compiler_complete_obj_file = compiler_getabspath(compiler_temp_dir "/") compiler_complete_obj_file
	}

	if (! compiler_truncate_file(compiler_main_obj_file))
		compiler_log_failure("Unable to truncate main object file \"" compiler_main_obj_file "\".")

	if (! compiler_truncate_file(compiler_calls_obj_file))
		compiler_log_failure("Unable to truncate calls object file \"" compiler_calls_obj_file "\".")

	if (! compiler_truncate_file(compiler_complete_obj_file))
		compiler_log_failure("Unable to truncate complete object file \"" compiler_complete_obj_file "\".")

	compiler_make_hash_initialize(1, 8)

	# Reserved keywords

	compiler_keywords["load"] = 1
	compiler_keywords["include"] = 1
	compiler_keywords["call"] = 1

	if (compiler_extended) {
		compiler_keywords["loadx"] = 1
		compiler_keywords["includex"] = 1
		compiler_keywords["callx"] = 1
	}

	if (compiler_deprecated_mode) {
		compiler_keywords["addpath"] = 1
		compiler_keywords["resetloader"] = 1
		compiler_keywords["finishloader"] = 1
	} else {
		compiler_keywords["loader_addpath"] = 1
		compiler_keywords["loader_flag"] = 1
		compiler_keywords["loader_reset"] = 1
		compiler_keywords["loader_finish"] = 1
	}

	compiler_keywords["begin_no_indent_block"] = 1
	compiler_keywords["begin_compiler_no_indent"] = 1
	compiler_keywords["end_no_indent_block"] = 1
	compiler_keywords["end_compiler_no_indent"] = 1
	compiler_keywords["begin_skip_block"] = 1
	compiler_keywords["begin_compiler_skip"] = 1
	compiler_keywords["end_skip_block"] = 1
	compiler_keywords["end_compiler_skip"] = 1
	compiler_keywords["begin_no_parse_block"] = 1
	compiler_keywords["begin_compiler_no_parse"] = 1
	compiler_keywords["end_no_parse_block"] = 1
	compiler_keywords["end_compiler_no_parse"] = 1

	compiler_keywords["BEGIN_NO_INDENT_BLOCK"] = 1
	compiler_keywords["BEGIN_COMPILER_NO_INDENT"] = 1	
	compiler_keywords["END_NO_INDENT_BLOCK"] = 1
	compiler_keywords["END_COMPILER_NO_INDENT"] = 1
	compiler_keywords["BEGIN_SKIP_BLOCK"] = 1
	compiler_keywords["BEGIN_COMPILER_SKIP"] = 1
	compiler_keywords["END_SKIP_BLOCK"] = 1
	compiler_keywords["END_COMPILER_SKIP"] = 1
	compiler_keywords["BEGIN_NO_PARSE_BLOCK"] = 1
	compiler_keywords["BEGIN_COMPILER_NO_PARSE"] = 1
	compiler_keywords["END_NO_PARSE_BLOCK"] = 1
	compiler_keywords["END_COMPILER_NO_PARSE"] = 1

	# Walk throughout.

	for (i = 0; i < files_count; i++) {
		abs = compiler_getabspath(files[i])

		compiler_flags[abs] = 1

		compiler_walk(abs)
	}

	# Finish

	close(compiler_calls_obj_file)
	close(compiler_main_obj_file)

	compiler_dump(compiler_calls_obj_file, compiler_complete_obj_file, 1)
	compiler_remove_file(compiler_calls_obj_file)

	compiler_dump(compiler_main_obj_file, compiler_complete_obj_file, 1)
	compiler_remove_file(compiler_main_obj_file)

	if (strip) {
		# Just use sed for now.

		compiler_log_message("strip: " compiler_complete_obj_file)

		if (strip_comments) {
			sed_args = sed_args "'/^[[:blank:]]*#/d;'"
		}
		if (strip_trailing_comments) {
			sed_args = sed_args "'s/[[:blank:]]\\+#[^'\\''|&;]*$//;'"
		}
		if (strip_leading_spaces) {
			sed_args = sed_args "'s/^[[:blank:]]\\+//;'"
		}
		if (strip_trailing_spaces) {
			sed_args = sed_args "'s/[[:blank:]]\\+$//;'"
		}
		if (sed_args) {
			if (system("sed -i " sed_args " \"" compiler_complete_obj_file "\"") != 0) {
				compiler_log_failure("Failed to strip object file with sed.")
			}
		}
		if (strip_blank_lines) {
			if (system("sed -i '/^$/d;' \"" compiler_complete_obj_file "\"") != 0) {
				compiler_log_failure("Failed to strip object file with sed.")
			}
		} else if (strip_extra_blank_lines) {
			if (system("sed -i '/./,/^$/!d;' \"" compiler_complete_obj_file "\"") != 0) {
				compiler_log_failure("Failed to strip object file with sed.")
			}
		}
	}

	if (shell) {
		compiler_log_message("add #! header: \"#!" shell "\" > " output_file)
		print "#!" shell "\n" > output_file
	}

	if (header_file) {
		compiler_log_message("add header file: " header_file " > " output_file)
		compiler_dump(header_file, output_file, 1)
		print "" >> output_file
	}

	# Add info header here next time.
	#
	# > if (!compiler_no_info)
	# > 	... add compile info header >> output_file

	compiler_dump(compiler_complete_obj_file, output_file, 1)

	compiler_remove_file(compiler_complete_obj_file)

	close(output_file)

	close("/dev/stdout")
	close("/dev/stderr")

	exit(0)
}


# Info Functions

function compiler_show_info_and_usage() {
	compiler_log_stderr("Prototype compiler for shell scripts based on Shell Script Loader")
	compiler_log_stderr("Version: " compiler_version)
	compiler_log_stderr("")
	compiler_log_stderr("Usage Summary: compiler.gawk [option [optarg] [option2] ...] file [file2 ...]")
	compiler_log_stderr("")
	compiler_log_stderr("Options:")
	compiler_log_stderr("")
	compiler_log_stderr("-a,  --addpath [path]  Add a path to the search list.")
	compiler_log_stderr("     --debug           Enable debug mode.")
	compiler_log_stderr("     --deprecated      Deprecated mode. Parse deprecated functions instead.")
	compiler_log_stderr("-h,  --help|--usage    Show this message")
	compiler_log_stderr("-H,  --header [file]   Insert a file at the top of the compiled form. This can")
	compiler_log_stderr("                       be used to insert program description and license info.")
	compiler_log_stderr("-ia, --ignore-addpaths Ignore embedded addpath commands in scripts.")
	compiler_log_stderr("-ir, --ignore-resets   Ignore embedded reset commands in scripts.")
	compiler_log_stderr("-n,  --no-info         Do not add informative comments.")
	compiler_log_stderr("-ni, --no-indent       Do not add extra alignment indents to contents when compiling.")
	compiler_log_stderr("-o,  --output [file]   Use file for output instead of stdout.")
	compiler_log_stderr("-O                     Optimize. (enables --strip-all-safe, and --no-info)")
	compiler_log_stderr("     --RS0             Parse commands based on RS0 (default).")
	compiler_log_stderr("     --RS0X            Parse commands based on RS0X (--extended).")
	compiler_log_stderr("     --RS0L            Parse commands based on RS0L (--deprecated).")
	compiler_log_stderr("     --RS0S            Parse commands based on RS0S (--deprecated + --extended).")
	compiler_log_stderr("     --sed             Use sed by default in some operations like stripping.")
	compiler_log_stderr("-s,  --shell [path]    Includes a '#!<path>' header to the output.")
	compiler_log_stderr("     --strip-bl        Strip all blank lines.")
	compiler_log_stderr("     --strip-c         Strip comments from code. (safe)")
	compiler_log_stderr("     --strip-ebl       Strip extra blank lines. (safe)")
	compiler_log_stderr("     --strip-ls        Strip leading spaces in every line of the code.")
	compiler_log_stderr("     --strip-tc        Strip trailing comments. (not really implemented yet)")
	compiler_log_stderr("     --strip-ts        Strip trailing spaces in every line of the code. (safe)")
	compiler_log_stderr("     --strip-all       Do all the strip methods mentioned above.")
	compiler_log_stderr("     --strip-all-safe  Do all the safe strip methods mentioned above.")
	compiler_log_stderr("     --tempdir [path]  Use a different directory for temporary files.")
	compiler_log_stderr("-x,  --extended        Parse extended functions loadx(), includex() and callx().")
	compiler_log_stderr("-V,  --version         Show version.")
	compiler_log_stderr("")
}

function compiler_show_version_info() {
	print(compiler_version)
}


# Walk Functions

function compiler_walk(file) {
	compiler_log_message("walk: " file)

	if (! compiler_test("-r", file))
		compiler_log_failure("File is not readable: " file,
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	compiler_write_to_main_obj_comment("--------------------------------------------------")
	compiler_write_to_main_obj_comment("(SOF) " file)
	compiler_write_to_main_obj_comment("--------------------------------------------------")

	compiler_walk_stack_file[compiler_walk_stack_i]           = compiler_walk_current_file
	compiler_walk_stack_line[compiler_walk_stack_i]           = compiler_walk_current_line
	compiler_walk_stack_line_number[compiler_walk_stack_i]    = compiler_walk_current_line_number
	compiler_walk_stack_noindent[compiler_walk_stack_i]       = compiler_walk_current_no_indent
	compiler_walk_stack_noindent_start[compiler_walk_stack_i] = compiler_walk_current_no_indent_start
	compiler_walk_stack_i++

	compiler_walk_current_file = file
	compiler_walk_current_line_number = 0
	compiler_walk_current_no_indent = 0
	compiler_walk_current_no_indent_start = 0

	while ((getline < file) > 0) {
		compiler_walk_current_line = $0
		++compiler_walk_current_line_number

		if ($1 in compiler_keywords) {
			if ($1 == "load") {
				compiler_walk_load()
			} else if ($1 == "include") {
				compiler_walk_include()
			} else if ($1 == "call") {
				compiler_walk_call()
			} else if ($1 == "loadx") {
				compiler_walk_loadx()
			} else if ($1 == "includex") {
				compiler_walk_includex()
			} else if ($1 == "callx") {
				compiler_walk_callx()
			} else if ($1 == "loader_addpath" || $1 == "addpath") {
				compiler_walk_addpath()
			} else if ($1 == "loader_flag") {
				# compiler_walk_flag()
				;
			} else if ($1 == "loader_reset" || $1 == "resetloader") {
				# compiler_walk_reset()
				;
			} else if ($1 == "loader_finish" || $1 == "finishloader") {
				# compiler_walk_finish()
				;
			} else if ($1 ~ /(begin_no_indent_block|BEGIN_NO_INDENT_BLOCK|begin_compiler_no_indent|BEGIN_COMPILER_NO_INDENT)/) {
				compiler_walk_no_indent_block_begin()
			} else if ($1 ~ /(end_no_indent_block|END_NO_INDENT_BLOCK|end_compiler_no_indent|END_COMPILER_NO_INDENT)/) {
				compiler_walk_no_indent_block_end()
			} else if ($1 ~ /(begin_skip_block|BEGIN_SKIP_BLOCK|begin_compiler_skip|BEGIN_COMPILER_SKIP)/) {
				compiler_walk_skip_block_begin()
			} else if ($1 ~ /(end_skip_block|END_SKIP_BLOCK|end_compiler_skip|END_COMPILER_SKIP)/) {
				compiler_walk_skip_block_end()
			} else if ($1 ~ /(begin_no_parse_block|BEGIN_NO_PARSE_BLOCK|begin_compiler_no_parse|BEGIN_COMPILER_NO_PARSE)/) {
				compiler_walk_no_parse_block_begin()
			} else if ($1 ~ /(end_no_parse_block|END_NO_PARSE_BLOCK|end_compiler_no_parse|END_COMPILER_NO_PARSE)/) {
				compiler_walk_no_parse_block_end()
			} else {
				compiler_log_failure("Compiler failure: Entered invalid block in compiler_walk().")
			}
		} else {
			compiler_write_to_main_obj(compiler_walk_current_line)
		}
	}

	compiler_walk_no_indent_block_end_check()

	compiler_write_to_main_obj_comment("--------------------------------------------------")
	compiler_write_to_main_obj_comment("(EOF) " file)
	compiler_write_to_main_obj_comment("--------------------------------------------------")

	close(file)

	if (compiler_walk_stack_i in compiler_walk_stack_file) {
		delete compiler_walk_stack_file[compiler_walk_stack_i]
		delete compiler_walk_stack_line_number[compiler_walk_stack_i]
		delete compiler_walk_stack_line[compiler_walk_stack_i]
	}

	--compiler_walk_stack_i
	compiler_walk_current_file            = compiler_walk_stack_file[compiler_walk_stack_i]
	compiler_walk_current_line            = compiler_walk_stack_line[compiler_walk_stack_i]
	compiler_walk_current_line_number     = compiler_walk_stack_line_number[compiler_walk_stack_i]
	compiler_walk_current_no_indent       = compiler_walk_stack_noindent[compiler_walk_stack_i]
	compiler_walk_current_no_indent_start = compiler_walk_stack_noindent_start[compiler_walk_stack_i]
}

function compiler_walk_load \
( \
\
	abs, argc, argv, base, co_statements, eai, extra_args, i, \
	leading_spaces, tokenc, tokenv \
)
{
	compiler_log_debug("compiler_walk_load() [" compiler_walk_current_line "]")

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	tokenc = compiler_get_tokens(compiler_walk_current_line, tokenv)

	argc = compiler_get_args(tokenv, tokenc, argv)

	if (argc < 2)
		compiler_log_failure("No argument entered.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	base = compiler_remove_quotes(argv[1])

	compiler_log_debug("compiler_walk_load: base = " base)

	if (base == "")
		compiler_log_failure("Representing string cannot be null.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	if (argc > 2) {
		extra_args = argv[2]

		for (i = 3; i < argc; i++)
			extra_args = extra_args " " argv[i]
	} else {
		extra_args = 0
	}

	if (argc < tokenc && tokenv[argc] !~ /^#/) {
		co_statements = tokenv[argc]

		for (i = argc + 1; i < tokenc; i++)
			co_statements = co_statements " " tokenv[i]

		leading_spaces = gensub(/[^ \t].*$/, "", 1, compiler_walk_current_line)
	} else {
		co_statements = 0
	}

	if (base ~ /^\.?\.?\//) {
		if (compiler_test("-f", base)) {
			abs = compiler_getabspath(base)

			compiler_flags[abs] = 1

			if (extra_args)
				compiler_write_to_main_obj("set -- " extra_args)

			compiler_walk(abs)

			if (co_statements)
				compiler_write_to_main_obj(leading_spaces ": " co_statements)

			return
		}
	} else {
		for (i = 0; i < compiler_paths_count; i++) {
			if (! compiler_test("-f", compiler_paths[i] "/" base))
				continue

			abs = compiler_getabspath(compiler_paths[i] "/" base)

			compiler_flags[abs] = 1
			compiler_flags[base] = 1

			if (extra_args)
				compiler_write_to_main_obj("set -- " extra_args)

			compiler_walk(abs)

			if (co_statements)
				compiler_write_to_main_obj(leading_spaces ": " co_statements)

			return
		}
	}

	compiler_log_failure("File not found: " base,
			compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
}

function compiler_walk_include \
( \
\
	abs, argc, argv, base, co_statements, extra_args, i, leading_spaces, \
	tokenc, tokenv \
)
{
	compiler_log_debug("compiler_walk_include() [" compiler_walk_current_line "]")

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	tokenc = compiler_get_tokens(compiler_walk_current_line, tokenv)

	argc = compiler_get_args(tokenv, tokenc, argv)

	if (argc < 2)
		compiler_log_failure("No argument entered.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	base = compiler_remove_quotes(argv[1])

	if (base == "")
		compiler_log_failure("Representing string cannot be null.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	if (argc > 2) {
		extra_args = argv[2]

		for (i = 3; i < argc; i++)
			extra_args = extra_args " " argv[i]
	} else {
		extra_args = 0
	}

	if (argc < tokenc && tokenv[argc] !~ /^#/) {
		co_statements = tokenv[argc]

		for (i = argc + 1; i < tokenc; i++)
			co_statements = co_statements " " tokenv[i]

		leading_spaces = gensub(/[^ \t].*$/, "", 1, compiler_walk_current_line)
	} else {
		co_statements = 0
	}

	if (base ~ /^\.?\.?\//) {
		abs = compiler_getabspath(base)

		if (abs in compiler_flags) {
			if (co_statements)
				compiler_write_to_main_obj(leading_spaces ": " co_statements)

			return
		}

		if (compiler_test("-f", base)) {
			compiler_flags[abs] = 1

			if (extra_args)
				compiler_write_to_main_obj("set -- " extra_args)

			compiler_walk(abs)

			if (co_statements)
				compiler_write_to_main_obj(leading_spaces ": " co_statements)

			return
		}
	} else {
		if (base in compiler_flags) {
			if (co_statements)
				compiler_write_to_main_obj(leading_spaces ": " co_statements)

			return
		}

		for (i = 0; i < compiler_paths_count; i++) {
			abs = compiler_getabspath(compiler_paths[i] "/" base)

			if (abs in compiler_flags) {
				compiler_flags[base] = 1

				if (co_statements)
					compiler_write_to_main_obj(leading_spaces ": " co_statements)

				return
			}

			if (compiler_test("-f", abs)) {
				compiler_flags[abs] = 1
				compiler_flags[base] = 1

				if (extra_args)
					compiler_write_to_main_obj("set -- " extra_args)

				compiler_walk(abs)

				if (co_statements)
					compiler_write_to_main_obj(leading_spaces ": " co_statements)

				return
			}
		}
	}

	compiler_log_failure("File not found: " base,
			compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
}

function compiler_walk_call \
( \
\
	abs, argc, argv, base, co_statements, extra_args, funcname, i, \
	leading_spaces, tokenc, tokenv \
)
{
	compiler_log_debug("compiler_walk_call() [" compiler_walk_current_line "]")

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	tokenc = compiler_get_tokens(compiler_walk_current_line, tokenv)

	argc = compiler_get_args(tokenv, tokenc, argv)

	if (argc < 2)
		compiler_log_failure("No argument entered.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	base = compiler_remove_quotes(argv[1])

	if (base == "")
		compiler_log_failure("Representing string cannot be null.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	if (argc > 2) {
		extra_args = argv[2]

		for (i = 3; i < argc; i++)
			extra_args = extra_args " " argv[i]
	} else {
		extra_args = 0
	}

	if (argc < tokenc && tokenv[argc] !~ /^#/) {
		co_statements = tokenv[argc]

		for (i = argc + 1; i < tokenc; i++)
			co_statements = co_statements " " tokenv[i]

	} else {
		co_statements = 0
	}

	leading_spaces = gensub(/[^ \t].*$/, "", 1, compiler_walk_current_line)

	if (base ~ /^\.?\.?\//) {
		abs = compiler_getabspath(base)

		if (abs in compiler_calls_hashes) {
			funcname = compiler_calls_hashes[abs]

			compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces)

			return
		}

		if (compiler_test("-f", abs)) {
			funcname = compiler_calls_create_function_name(abs)

			compiler_calls_hashes[abs] = funcname

			compiler_calls_include_file(abs, funcname)

			compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces)

			return
		}
	} else {
		if (base in compiler_calls_hashes) {
			funcname = compiler_calls_hashes[base]

			compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces)

			return
		}

		for (i = 0; i < compiler_paths_count; i++) {
			abs =  compiler_getabspath(compiler_paths[i] "/" base)

			if (abs in compiler_calls_hashes) {
				funcname = compiler_calls_hashes[abs]

				compiler_calls_hashes[base] = funcname

				compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces)

				return
			}

			if (compiler_test("-f", abs)) {
				funcname = compiler_calls_create_function_name(abs)

				compiler_calls_hashes[abs] = funcname
				compiler_calls_hashes[base] = funcname

				compiler_calls_include_file(abs, funcname)

				compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces)

				return
			}
		}
	}
}

function compiler_walk_loadx \
( \
\
	abs, argc, argv, base, complete_expr, co_statements, \
	cmd, eai, extra_args, file_expr, filename, find_path, \
	find_path_quoted, i, leading_spaces, list, list_count, prefix, \
	prefix_expr, plain, sub_, subprefix, subprefix_quoted, temp, \
	test_opt, tokenc, tokenv, wholepath_matching \
)
{
	compiler_log_debug("compiler_walk_loadx() [" compiler_walk_current_line "]")

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	tokenc = compiler_get_tokens(compiler_walk_current_line, tokenv)

	argc = compiler_get_args(tokenv, tokenc, argv)

	if (argc < 2)
		compiler_log_failure("No argument follows.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	if (argv[1] ~ /[?*]/) {
		base = compiler_remove_quotes(argv[1])
		eai = 2
		plain = 0
		test_opt = "-name"
		wholepath_matching = 0
	} else if (argv[1] ~ /^["']?(-name|-iname)["']?$/) {
		base = compiler_remove_quotes(argv[2])
		eai = 3
		plain = 0
		test_opt = compiler_remove_quotes(argv[1])
		wholepath_matching = 0
	} else if (argv[1] ~ /^["']?(-regex|-iregex)["']?$/) {
		base = compiler_remove_quotes(argv[2])
		eai = 3
		plain = 0
		test_opt = compiler_remove_quotes(argv[1])
		wholepath_matching = 1
	} else {
		base = compiler_remove_quotes(argv[1])
		eai = 2
		plain = 1
	}

	if (base == "")
		compiler_log_failure("Representing string cannot be null.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	if (argc > eai) {
		extra_args = argv[eai]

		for (i = eai + 1; i < argc; i++)
			extra_args = extra_args " " argv[i]
	} else {
		extra_args = 0
	}

	if (argc < tokenc && tokenv[argc] !~ /^#/) {
		co_statements = tokenv[argc]

		for (i = argc + 1; i < tokenc; i++)
			co_statements = co_statements " " tokenv[i]

		leading_spaces = gensub(/[^ \t].*$/, "", 1, compiler_walk_current_line)
	} else {
		co_statements = 0
	}

	if (plain) {
		if (base ~ /^\.?\.?\//) {
			if (compiler_test("-f", base)) {
				abs = compiler_getabspath(base)

				compiler_flags[abs] = 1

				if (extra_args)
					compiler_write_to_main_obj("set -- " extra_args)

				compiler_walk(abs)

				if (co_statements)
					compiler_write_to_main_obj(leading_spaces ": " co_statements)

				return
			}
		} else {
			for (i = 0; i < compiler_paths_count; i++) {
				if (! compiler_test("-f", compiler_paths[i] "/" base))
					continue

				abs = compiler_getabspath(compiler_paths[i] "/" base)

				compiler_flags[abs] = 1
				compiler_flags[base] = 1

				if (extra_args)
					compiler_write_to_main_obj("set -- " extra_args)

				compiler_walk(abs)

				if (co_statements)
					compiler_write_to_main_obj(leading_spaces ": " co_statements)

				return
			}
		}

		compiler_log_failure("File not found: " base,
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
	} else {
		match(base, /^(.*\/)?(.*)/, temp)
		file_expr = temp[2]
		subprefix = temp[1]

		list_count = 0

		if (file_expr == "")
			compiler_log_failure("Expression represents no file: " base,
					compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

		if (subprefix ~ /[*?]/)
			compiler_log_failure("Expressions for directories are not supported: " subprefix,
					compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

		if (subprefix ~ /^\.?\.?\//) {
			if (! compiler_test("-d", subprefix))
				compiler_log_failure("Directory not found: " subprefix,
						compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

			if (! compiler_test("-x", subprefix))
				compiler_log_failure("Directory is not accessible: " subprefix,
						compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

			if (! compiler_test("-r", subprefix))
				compiler_log_failure("Directory is not searchable: " subprefix,
						compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

			if (wholepath_matching) {
				prefix_expr = compiler_gen_regex_literal(subprefix)
			} else {
				prefix_expr = ""
			}

			complete_expr = compiler_gen_doublequotes_form(prefix_expr file_expr)

			subprefix_quoted = compiler_gen_doublequotes_form(subprefix)

			cmd = "find " subprefix_quoted " -maxdepth 1 -xtype f " test_opt " " complete_expr " -printf '%f\\n'"

			compiler_log_debug("cmd = " cmd)

			if ((cmd | getline filename) > 0) {
				do {
					list[list_count++] = filename
				} while ((cmd | getline filename) > 0)

				close(cmd)

				prefix = compiler_getabspath(subprefix)

				for (i = 0; i < list_count; i++) {
					abs = prefix list[i]

					compiler_flags[abs] = 1

					if (extra_args)
						compiler_write_to_main_obj("set -- " extra_args)

					compiler_walk(abs)
				}

				if (co_statements)
					compiler_write_to_main_obj(leading_spaces ": " co_statements)

				return
			}

			close(cmd)
		} else {
			for (i = 0; i < compiler_paths_count; i++) {

				find_path = compiler_paths[i] "/" subprefix

				if (! compiler_test("-d", find_path))
					continue

				if (! compiler_test("-x", find_path))
					compiler_log_failure("Directory is not accessible: " find_path,
							compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

				if (! compiler_test("-r", find_path))
					compiler_log_failure("Directory is not searchable: " find_path,
							compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

				if (wholepath_matching) {
					prefix_expr = compiler_gen_regex_literal(find_path)
				} else {
					prefix_expr = ""
				}

				complete_expr = compiler_gen_doublequotes_form(prefix_expr file_expr)

				find_path_quoted = compiler_gen_doublequotes_form(find_path)

				cmd = "find " find_path_quoted " -maxdepth 1 -xtype f " test_opt " " complete_expr " -printf '%f\\n'"

				compiler_log_debug("cmd = " cmd)

				if ((cmd | getline filename) > 0) {
					do {
						list[list_count++] = filename
					} while ((cmd | getline filename) > 0)

					close(cmd)

					prefix = compiler_getabspath(find_path)

					compiler_log_debug("prefix = " prefix)

					for (i = 0; i < list_count; i++) {
						filename = list[i]
						abs = prefix filename
						sub_ = subprefix filename

						compiler_flags[abs] = 1
						compiler_flags[sub_] = 1

						if (extra_args)
							compiler_write_to_main_obj("set -- " extra_args)

						compiler_walk(abs)
					}

					if (co_statements)
						compiler_write_to_main_obj(leading_spaces ": " co_statements)

					return
				}

				close(cmd)
			}
		}

		compiler_log_failure("No file was found with expression '" base "'.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
	}
}

function compiler_walk_includex \
( \
\
	abs, argc, argv, base, complete_expr, co_statements, \
	cmd, eai, extra_args, file_expr, filename, find_path, \
	find_path_quoted, i, leading_spaces, list, list_count, prefix, \
	prefix_expr, plain, sub_, subprefix, subprefix_quoted, temp, \
	test_opt, tokenc, tokenv, wholepath_matching \
)
{
	compiler_log_debug("compiler_walk_includex() [" compiler_walk_current_line "]")

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	tokenc = compiler_get_tokens(compiler_walk_current_line, tokenv)

	argc = compiler_get_args(tokenv, tokenc, argv)

	if (argc < 2)
		compiler_log_failure("No argument follows.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	if (argv[1] ~ /[?*]/) {
		base = compiler_remove_quotes(argv[1])
		eai = 2
		plain = 0
		test_opt = "-name"
		wholepath_matching = 0
	} else if (argv[1] ~ /^["']?(-name|-iname)["']?$/) {
		base = compiler_remove_quotes(argv[2])
		eai = 3
		plain = 0
		test_opt = compiler_remove_quotes(argv[1])
		wholepath_matching = 0
	} else if (argv[1] ~ /^["']?(-regex|-iregex)["']?$/) {
		base = compiler_remove_quotes(argv[2])
		eai = 3
		plain = 0
		test_opt = compiler_remove_quotes(argv[1])
		wholepath_matching = 1
	} else {
		base = compiler_remove_quotes(argv[1])
		eai = 2
		plain = 1
	}

	if (base == "")
		compiler_log_failure("Representing string cannot be null.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	if (argc > eai) {
		extra_args = argv[eai]

		for (i = eai + 1; i < argc; i++)
			extra_args = extra_args " " argv[i]
	} else {
		extra_args = 0
	}

	if (argc < tokenc && tokenv[argc] !~ /^#/) {
		co_statements = tokenv[argc]

		for (i = argc + 1; i < tokenc; i++)
			co_statements = co_statements " " tokenv[i]

		leading_spaces = gensub(/[^ \t].*$/, "", 1, compiler_walk_current_line)
	} else {
		co_statements = 0
	}

	if (plain) {
		if (base ~ /^\.?\.?\//) {
			abs = compiler_getabspath(base)

			if (abs in compiler_flags) {
				if (co_statements)
					compiler_write_to_main_obj(leading_spaces ": " co_statements)

				return
			}

			if (compiler_test("-f", base)) {
				compiler_flags[abs] = 1

				if (extra_args)
					compiler_write_to_main_obj("set -- " extra_args)

				compiler_walk(abs)

				if (co_statements)
					compiler_write_to_main_obj(leading_spaces ": " co_statements)

				return
			}
		} else {
			if (base in compiler_flags) {
				if (co_statements)
					compiler_write_to_main_obj(leading_spaces ": " co_statements)

				return
			}

			for (i = 0; i < compiler_paths_count; i++) {
				abs = compiler_getabspath(compiler_paths[i] "/" base)

				if (abs in compiler_flags) {
					compiler_flags[base] = 1

					if (co_statements)
						compiler_write_to_main_obj(leading_spaces ": " co_statements)

					return
				}

				if (compiler_test("-f", abs)) {
					compiler_flags[abs] = 1
					compiler_flags[base] = 1

					if (extra_args)
						compiler_write_to_main_obj("set -- " extra_args)

					compiler_walk(abs)

					if (co_statements)
						compiler_write_to_main_obj(leading_spaces ": " co_statements)

					return
				}
			}
		}

		compiler_log_failure("File not found: " base,
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
	} else {
		match(base, /^(.*\/)?(.*)/, temp)
		file_expr = temp[2]
		subprefix = temp[1]

		list_count = 0

		if (file_expr == "")
			compiler_log_failure("Expression represents no file: " base,
					compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

		if (subprefix ~ /[*?]/)
			compiler_log_failure("Expressions for directories are not supported: " subprefix,
					compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

		if (subprefix ~ /^\.?\.?\//) {
			if (! compiler_test("-d", subprefix))
				compiler_log_failure("Directory not found: " subprefix,
						compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

			if (! compiler_test("-x", subprefix))
				compiler_log_failure("Directory is not accessible: " subprefix,
						compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

			if (! compiler_test("-r", subprefix))
				compiler_log_failure("Directory is not searchable: " subprefix,
						compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

			if (wholepath_matching) {
				prefix_expr = compiler_gen_regex_literal(subprefix)
			} else {
				prefix_expr = ""
			}

			complete_expr = compiler_gen_doublequotes_form(prefix_expr file_expr)

			subprefix_quoted = compiler_gen_doublequotes_form(subprefix)

			cmd = "find " subprefix_quoted " -maxdepth 1 -xtype f " test_opt " " complete_expr " -printf '%f\\n'"

			if ((cmd | getline filename) > 0) {
				do {
					list[list_count++] = filename
				} while ((cmd | getline filename) > 0)

				close(cmd)

				prefix = compiler_getabspath(subprefix)

				for (i = 0; i < list_count; i++) {
					abs = prefix list[i]

					if (abs in compiler_flags)
						continue

					compiler_flags[abs] = 1

					if (extra_args)
						compiler_write_to_main_obj("set -- " extra_args)

					compiler_walk(abs)
				}

				if (co_statements)
					compiler_write_to_main_obj(leading_spaces ": " co_statements)

				return
			}

			close(cmd)
		} else {
			for (i = 0; i < compiler_paths_count; i++) {
				find_path = compiler_paths[i] "/" subprefix

				if (! compiler_test("-d", find_path))
					continue

				if (! compiler_test("-x", find_path))
					compiler_log_failure("Directory is not accessible: " find_path,
							compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

				if (! compiler_test("-r", find_path))
					compiler_log_failure("Directory is not searchable: " find_path,
							compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

				if (wholepath_matching) {
					prefix_expr = compiler_gen_regex_literal(find_path)
				} else {
					prefix_expr = ""
				}

				complete_expr = compiler_gen_doublequotes_form(prefix_expr file_expr)

				find_path_quoted = compiler_gen_doublequotes_form(find_path)

				cmd = "find " find_path_quoted " -maxdepth 1 -xtype f " test_opt " " complete_expr " -printf '%f\\n'"

				if ((cmd | getline filename) > 0) {
					do {
						list[list_count++] = filename
					} while ((cmd | getline filename) > 0)

					close(cmd)

					prefix = compiler_getabspath(find_path)

					for (i = 0; i < list_count; i++) {
						filename = list[i]
						abs = prefix filename
						sub_ = subprefix filename

						if (abs in compiler_flags)
							continue

						compiler_flags[abs] = 1
						compiler_flags[sub_] = 1

						if (extra_args)
							compiler_write_to_main_obj("set -- " extra_args)

						compiler_walk(abs)
					}

					if (co_statements)
						compiler_write_to_main_obj(leading_spaces ": " co_statements)

					return
				}

				close(cmd)
			}
		}

		compiler_log_failure("No file was found with expression '" base "'",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
	}
}

function compiler_walk_callx \
( \
\
	abs, argc, argv, base,  complete_expr, co_statements, cmd, eai, extra_args, \
	file_expr, filename, find_path, find_path_quoted, funcname, i, leading_spaces, \
	list, list_count, prefix, prefix_expr, plain, sub_, subprefix, \
	subprefix_quoted, temp, test_opt, tokenc, tokenv, wholepath_matching \
)
{
	compiler_log_debug("compiler_walk_callx() [" compiler_walk_current_line "]")

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	tokenc = compiler_get_tokens(compiler_walk_current_line, tokenv)

	argc = compiler_get_args(tokenv, tokenc, argv)

	if (argc < 2)
		compiler_log_failure("No argument follows.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	if (argv[1] ~ /[?*]/) {
		base = compiler_remove_quotes(argv[1])
		eai = 2
		plain = 0
		test_opt = "-name"
		wholepath_matching = 0
	} else if (argv[1] ~ /^["']?(-name|-iname)["']?$/) {
		base = compiler_remove_quotes(argv[2])
		eai = 3
		plain = 0
		test_opt = compiler_remove_quotes(argv[1])
		wholepath_matching = 0
	} else if (argv[1] ~ /^["']?(-regex|-iregex)["']?$/) {
		base = compiler_remove_quotes(argv[2])
		eai = 3
		plain = 0
		test_opt = compiler_remove_quotes(argv[1])
		wholepath_matching = 1
	} else {
		base = compiler_remove_quotes(argv[1])
		eai = 2
		plain = 1
	}

	if (base == "")
		compiler_log_failure("Representing string cannot be null.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	if (argc > eai) {
		extra_args = argv[eai]

		for (i = eai + 1; i < argc; i++)
			extra_args = extra_args " " argv[i]
	} else {
		extra_args = 0
	}

	if (argc < tokenc && tokenv[argc] !~ /^#/) {
		co_statements = tokenv[argc]

		for (i = argc + 1; i < tokenc; i++)
			co_statements = co_statements " " tokenv[i]

	} else {
		co_statements = 0
	}

	leading_spaces = gensub(/[^ \t].*$/, "", 1, compiler_walk_current_line)

	if (plain) {
		if (base ~ /^\.?\.?\//) {
			abs = compiler_getabspath(base)

			if (abs in compiler_calls_hashes) {
				funcname = compiler_calls_hashes[abs]

				compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces)

				return
			}

			if (compiler_test("-f", abs)) {
				funcname = compiler_calls_create_function_name(abs)

				compiler_calls_hashes[abs] = funcname

				compiler_calls_include_file(abs, funcname)

				compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces)

				return
			}
		} else {
			if (base in compiler_calls_hashes) {
				funcname = compiler_calls_hashes[base]

				compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces)

				return
			}

			for (i = 0; i < compiler_paths_count; i++) {
				abs = compiler_getabspath(compiler_paths[i] "/" base)

				if (abs in compiler_calls_hashes) {
					funcname = compiler_calls_hashes[abs]

					compiler_calls_hashes[base] = funcname

					compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces)

					return
				}

				if (compiler_test("-f", abs)) {
					funcname = compiler_calls_create_function_name(abs)

					compiler_calls_hashes[abs] = funcname
					compiler_calls_hashes[base] = funcname

					compiler_calls_include_file(abs, funcname)

					compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces)

					return
				}
			}
		}

		compiler_log_failure("File not found: " base,
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
	} else {
		match(base, /^(.*\/)?(.*)/, temp)
		file_expr = temp[2]
		subprefix = temp[1]

		list_count = 0

		if (file_expr == "")
			compiler_log_failure("Expression represents no file: " base,
					compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

		if (subprefix ~ /[*?]/)
			compiler_log_failure("Expressions for directories are not supported: " subprefix,
					compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

		if (subprefix ~ /^\.?\.?\//) {
			if (! compiler_test("-d", subprefix))
				compiler_log_failure("Directory not found: " subprefix,
						compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

			if (! compiler_test("-x", subprefix))
				compiler_log_failure("Directory is not accessible: " subprefix,
						compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

			if (! compiler_test("-r", subprefix))
				compiler_log_failure("Directory is not searchable: " subprefix,
						compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

			if (wholepath_matching) {
				prefix_expr = compiler_gen_regex_literal(subprefix)
			} else {
				prefix_expr = ""
			}

			complete_expr = compiler_gen_doublequotes_form(prefix_expr file_expr)

			subprefix_quoted = compiler_gen_doublequotes_form(subprefix)

			cmd = "find " subprefix_quoted " -maxdepth 1 -xtype f " test_opt " " complete_expr " -printf '%f\\n'"

			if ((cmd | getline filename) > 0) {
				prefix = compiler_getabspath(subprefix)

				do {
					abs = prefix filename

					if (abs in compiler_calls_hashes) {
						funcname = compiler_calls_hashes[abs]

						list[list_count++] = funcname
					} else {
						funcname = compiler_calls_create_function_name(abs)

						compiler_calls_hashes[abs] = funcname

						compiler_calls_include_file(abs, funcname)

						list[list_count++] = funcname
					}
				} while ((cmd | getline filename) > 0)

				close(cmd)

				if (list_count > 1) {
					compiler_calls_write_group_call(list, extra_args, co_statements, leading_spaces, base, test_opt)
				} else {
					compiler_calls_write_call(list[0], extra_args, co_statements, leading_spaces)
				}

				return
			}

			close(cmd)
		} else {
			for (i = 0; i < compiler_paths_count; i++) {
				find_path = compiler_paths[i] "/" subprefix

				if (! compiler_test("-d", find_path))
					continue

				if (! compiler_test("-x", find_path))
					compiler_log_failure("Directory is not accessible: " find_path,
							compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

				if (! compiler_test("-r", find_path))
					compiler_log_failure("Directory is not searchable: " find_path,
							compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

				if (wholepath_matching) {
					prefix_expr = compiler_gen_regex_literal(find_path)
				} else {
					prefix_expr = ""
				}

				complete_expr = compiler_gen_doublequotes_form(prefix_expr file_expr)

				find_path_quoted = compiler_gen_doublequotes_form(find_path)

				cmd = "find " find_path_quoted " -maxdepth 1 -xtype f " test_opt " " complete_expr " -printf '%f\\n'"

				if ((cmd | getline filename) > 0) {
					prefix = compiler_getabspath(find_path)

					do {
						abs = prefix filename
						sub_ = subprefix filename

						if (sub_ in compiler_calls_hashes) {
							funcname = compiler_calls_hashes[sub_]
						} else if (abs in compiler_calls_hashes) {
							funcname = compiler_calls_hashes[abs]

							compiler_calls_hashes[sub_] = funcname
						} else {
							funcname = compiler_calls_create_function_name(abs)

							compiler_calls_hashes[abs] = funcname
							compiler_calls_hashes[sub_] = funcname

							compiler_calls_include_file(abs, funcname)
						}

						list[list_count++] = funcname
					} while ((cmd | getline filename) > 0)

					close(cmd)

					if (list_count > 1) {
						compiler_calls_write_group_call(list, extra_args, co_statements, leading_spaces, base, test_opt)
					} else {
						compiler_calls_write_call(list[0], extra_args, co_statements)
					}

					return
				}

				close(cmd)
			}
		}

		compiler_log_failure("No file was found with expression '" base "'.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
	}
}

function compiler_walk_addpath(  argc, argv, i, path, tokenc, tokenv) {
	compiler_log_debug("compiler_walk_addpath() [" compiler_walk_current_line "]")

	if (compiler_ignoreaddpaths) {
		compiler_write_to_main_obj(compiler_walk_current_line)
		return
	}

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	tokenc = compiler_get_tokens(compiler_walk_current_line, tokenv)

	argc = compiler_get_args(tokenv, tokenc, argv)

	if (argc < 2)
		compiler_log_failure("No argument entered.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	for (i = 1; i < argc; i++) {
		path = compiler_remove_quotes(argv[i])

		if (! compiler_test("-d", path)) {
			compiler_log_failure("Directory not found: " path ", cwd: " compiler_getcwd(),
					compiler_walk_current_file, compiler_walk_current_line_number, $1 " " path)

			return
		}

		compiler_addpath(path)
	}
}


function compiler_walk_flag() {
	compiler_log_debug("compiler_walk_flag() [" compiler_walk_current_line "]")

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	tokenc = compiler_get_tokens(compiler_walk_current_line, tokenv)

	argc = compiler_get_args(tokenv, tokenc, argv)

	if (argc < 2)
		compiler_log_failure("No argument entered.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	base = compiler_remove_quotes(argv[1])

	compiler_log_debug("compiler_walk_flag: base = " base)

	if (base == "")
		compiler_log_failure("Representing string cannot be null.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)

	if (argc < tokenc && tokenv[argc] !~ /^#/) {
		co_statements = tokenv[argc]

		for (i = argc + 1; i < tokenc; i++)
			co_statements = co_statements " " tokenv[i]

		leading_spaces = gensub(/[^ \t].*$/, "", 1, compiler_walk_current_line)
	} else {
		co_statements = 0
	}

	if (co_statements)
		compiler_write_to_main_obj(leading_spaces ": " co_statements)

	abs = compiler_getabspath(base)

	compiler_flags[abs] = 1
}

function compiler_walk_reset(  argc, argv, tokenc, tokenv) {
	compiler_log_debug("compiler_walk_reset() [" compiler_walk_current_line "]")

	if (compiler_ignoreresets) {
		compiler_write_to_main_obj(compiler_walk_current_line)
		return
	}

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	tokenc = compiler_get_tokens(compiler_walk_current_line, tokenv)

	argc = compiler_get_args(tokenv, tokenc, argv)

	if (argc < 2) {
		delete compiler_flags

		delete compiler_paths
		delete compiler_paths_flags
		compiler_paths_count = 0
	} else {
		type = compiler_remove_quotes(argv[1])

		if (type == "flags") {
			delete compiler_flags
		} else if (type == "paths") {
			delete compiler_paths
			delete compiler_paths_flags
			compiler_paths_count = 0
		} else {
			compiler_log_failure("Invalid argument: \"" argv[1] "\"",
					compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
		}
	}
}

function compiler_walk_finish() {
	compiler_log_debug("compiler_walk_finish() [" compiler_walk_current_line "]")

	# Anything else to do?
}

function compiler_walk_no_indent_block_begin() {
	if (compiler_walk_current_no_indent) {
		compiler_log_failure("Already inside a no-indent block which started at line " compiler_walk_current_no_indent_start ".",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
	} else {
		compiler_walk_current_no_indent = 1
		compiler_walk_current_no_indent_start = compiler_walk_current_line_number
	}
}

function compiler_walk_no_indent_block_end() {
	if (compiler_walk_current_no_indent) {
		compiler_walk_current_no_indent = 0
		compiler_walk_current_no_indent_start = 0
	} else {
		compiler_log_failure("Not inside a no-indent block.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
	}
}

function compiler_walk_no_indent_block_end_check() {
	if (compiler_walk_current_no_indent)
		compiler_log_failure("End of no-indent block that started at line " compiler_walk_current_no_indent_start " was not found.",
				compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
}

function compiler_walk_skip_block_begin(  found_end_of_block, start_of_block_line_no) {
	compiler_log_debug("compiler_walk_skip_block_begin() [ file = " compiler_walk_current_file ", line no = " compiler_walk_current_line_number "]")

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	found_end_of_block = 0
	start_of_block_line_no = compiler_walk_current_line_number

	while ((getline < compiler_walk_current_file) > 0) {
		++compiler_walk_current_line_number

		if ($1 ~ /#(end_skip_block|END_SKIP_BLOCK|end_compiler_skip|END_COMPILER_SKIP)/) {
			found_end_of_block = 1
			break
		}
	}

	if (!found_end_of_block)
		compiler_log_failure("End of skip block not found.",
				compiler_walk_current_file, start_of_block_line_no)

	compiler_write_to_main_obj_comment($0)
}

function compiler_walk_skip_block_end() {
	compiler_log_failure("Not inside a no-skip block.",
			compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
}

function compiler_walk_no_parse_block_begin(  found_end_of_block, start_of_block_line_no) {
	compiler_log_debug("compiler_walk_no_parse_block_begin() [ file = " compiler_walk_current_file ", line no = " compiler_walk_current_line_number "]")

	compiler_write_to_main_obj_comment(compiler_walk_current_line)

	found_end_of_block = 0
	start_of_block_line_no = compiler_walk_current_line_number

	while ((getline < compiler_walk_current_file) > 0) {
		++compiler_walk_current_line_number

		compiler_write_to_main_obj_comment($0)

		if ($1 ~ /#(end_no_parse_block|END_NO_PARSE_BLOCK|end_compiler_no_parse|END_COMPILER_NO_PARSE)/) {
			found_end_of_block = 1
			break
		}

		compiler_write_to_main_obj($0)
	}

	if (!found_end_of_block)
		compiler_log_failure("End of no parse block not found.",
				compiler_walk_current_file, start_of_block_line_no)

	compiler_write_to_main_obj_comment($0)
}

function compiler_walk_no_parse_block_end() {
	compiler_log_failure("Not inside a no-parse block.",
			compiler_walk_current_file, compiler_walk_current_line_number, compiler_walk_current_line)
}


# Sub / Misc. Functions

function compiler_addpath(path) {
	compiler_log_debug("compiler_addpath(\"" path "\")")

	path = compiler_getabspath(path "/.")

	if (! (path in compiler_paths_flags)) {
		compiler_paths[compiler_paths_count++] = path
		compiler_paths_flags[path] = 1
	}
}

function compiler_calls_create_function_name(seed,   funcname, hash, i) {
	compiler_log_debug("compiler_calls_create_function_name(\"" seed "\")")

	hash = compiler_make_hash(seed)
	i = 0

	do {
		funcname = "call_" hash sprintf("%02d", i++)
	} while (funcname in compiler_calls_funcnames)

	compiler_calls_funcnames[funcname] = 1

	return funcname
}

function compiler_calls_include_file(path, funcname) {
	compiler_log_debug("compiler_calls_include_file(\"" path "\", \"" funcname "\")")

	compiler_write_to_calls_obj_comment("--------------------------------------------------")
	compiler_write_to_calls_obj_comment("(CALL) " path)
	compiler_write_to_calls_obj_comment("--------------------------------------------------\n")

	compiler_write_to_calls_obj(funcname "() {\n\t(")

	if (compiler_no_indent || compiler_walk_current_no_indent) {
		compiler_dump(path, compiler_calls_obj_file, 1)
	} else {
		compiler_dump(path, compiler_calls_obj_file, 1, "\t\t")
	}

	compiler_write_to_calls_obj("\t)\n\treturn\n}\n")
}

function compiler_calls_write_call(funcname, extra_args, co_statements, leading_spaces,   line) {
	compiler_log_debug("compiler_calls_write_call(\"" funcname "\", \"" extra_args "\", \"" co_statements "\")")

	if (leading_spaces && leading_spaces != "") {
		line = leading_spaces funcname
	} else {
		line = funcname
	}

	if (extra_args)
		line = line " " extra_args

	if (co_statements)
		line = line " " co_statements

	compiler_write_to_main_obj(line)
}

function compiler_calls_write_group_call(funclist, extra_args, co_statements, leading_spaces, base, test_opt,   comment, group_call_funcname, i, seed) {
	compiler_log_debug("compiler_calls_write_group_call({ " funclist[0] ", ... } , " extra_args ", " co_statements ") [" base "]")

	for (i in funclist)
		seed = seed "." funclist[i]

	if (extra_args)
		seed = seed "." extra_args

	if (seed in compiler_calls_groupcallseeds) {
		group_call_funcname = compiler_calls_groupcallseeds[seed]
	} else {
		group_call_funcname = compiler_calls_create_function_name(seed)

		compiler_calls_groupcallseeds[seed] = group_call_funcname

		comment = "(GROUPCALL) (" substr(test_opt, 2) ") \"" base "\""

		if (extra_args)
			comment = comment " " extra_args

		compiler_write_to_calls_obj_comment("--------------------------------------------------")
		compiler_write_to_calls_obj_comment(comment)
		compiler_write_to_calls_obj_comment("--------------------------------------------------\n")

		compiler_write_to_calls_obj(group_call_funcname "() {")

		compiler_write_to_calls_obj("\tr=0")

		if (extra_args) {
			for (i in funclist) {
				compiler_write_to_calls_obj("\t" funclist[i] " " extra_args)
				compiler_write_to_calls_obj("\ttest $? -ne 0 && r=1")
			}
		} else {
			for (i in funclist) {
				compiler_write_to_calls_obj("\t" funclist[i])
				compiler_write_to_calls_obj("\ttest $? -ne 0 && r=1")
			}
		}

		compiler_write_to_calls_obj("\treturn $r")
		compiler_write_to_calls_obj("}\n")
	}

	if (co_statements) {
		compiler_write_to_main_obj(leading_spaces group_call_funcname " " co_statements)
	} else {
		compiler_write_to_main_obj(leading_spaces group_call_funcname)
	}
}

function compiler_dump(input, output, append, indent,   arrow, line) {
	if (append) {
		arrow = " >> "
	} else {
		arrow = " > "
	}

	compiler_log_message("dump: " input arrow output)

	if ((getline line < input) > 0) {
		if (append) {
			print indent line >> output
		} else {
			close(output)

			# Should truncate but no that's why we use
			# truncate() everywhere before using this function.
			# This won't be changed for the sake of
			# consistency.

			print indent line > output
		}

		while ((getline line < input) > 0)
			print indent line >> output

		# Not sure if it's necessary to close the output but it's ok.

		close(output)
	}

	close(input)
}

function compiler_getabspath(path,   abs, array, c, f, nf, node, t, tokens) {
	node = (path ~ /\/$/)

	if (path !~ /^\//)
		path = compiler_wd "/" path

	nf = split(path, array, "/")

	t = 0

	for (f = 1; f <= nf; ++f) {
		c = array[f]

		if (c == "." || c == "") {
			continue
		} else if (c == "..") {
			if (t)
				--t
		} else {
			tokens[t++]=c
		}
	}

	if (t) {
		abs = "/" tokens[0]

		for (i = 1; i < t; ++i)
			abs = abs "/" tokens[i]

		if (node)
			abs = abs "/"
	} else if (node) {
		abs = "/"
	} else {
		abs = "/."
	}

	return abs
}

function compiler_gen_regex_literal(string) {
	gsub(/[\$\(\)\*\+\.\?\[\\\]\^\{\|\}]/, "\\\\&", string)
	return string
}

function compiler_gen_doublequotes_form(string) {
	return "\"" gensub(/["\$`\\]/, "\\\\&", 1, string) "\""
}

function compiler_get_args(tokenv, tokenc, argv,   argc) {
	compiler_log_debug("compiler_get_args()")

	argc = 0

	for (i in argv)
		delete argv[i]

	# Sometimes 'for (i in array)' does not yield indices in sorted
	# order so we depend on tokenc.

	for (i = 0; i < tokenc; i++v) {
		if (tokenv[i] ~ /^(#|\||&|;|[[:digit:]]*[<>])/) {
			return argc
		} else {
			argv[argc++] = tokenv[i]
		}
	}

	return argc
}

function compiler_get_tokens(string, tokenv,   i, temp, token, tokenc) {
	# TODO:
	# * Something feels not right with '\\.?' but perhaps it's already correct.
	# * In some comparisons, unexpected EOS is not reported.

	compiler_log_debug("compiler_get_tokens(\"" string "\", ... )")

	for (i in tokenv)
		delete tokenv[i]

	delete tokenv

	# Check if whole string is just a comment.

	if (match(string, /^[[:blank:]]*(#.*)/, temp)) {
		tokenv[0] = temp[1]
		return 1
	}

	token = ""
	tokenc = 0
	subtoken_size = 0

	while (length(string)) {
		# Comments

		if (match(string, /^[[:blank:]]+(#.*)/, temp)) {
			if (length(token))
				tokenv[tokenc++] = token

			tokenv[tokenc++] = temp[1]

			return tokenc
		}

		# New tokens coming

		if (match(string, /^[[:blank:]]+(.*)/, temp)) {
			if (length(token)) {
				tokenv[tokenc++] = token
				token = ""
			}

			string = temp[1]

			if (! length(string))
				break
		}

		# Single quoted strings

		if (match(string, /^('[^']*'?)(.*)/, temp)) {
			token = token temp[1]
			string = temp[2]
			continue
		}

		# Backquotes (old command substitution)

		if (match(string, /^(`(\\`|[^`])*`?)(.*)/, temp)) {
			token = token temp[1]
			string = temp[2]
			continue
		}

		# Double quoted strings / dollar-sign based expansions or substitutions

		if (string ~ /^"/) {
			subtoken_size = compiler_get_tokens_get_subtoken_size_doublequotes(string)
		} else if (string ~ /^\$/) {
			subtoken_size = compiler_get_tokens_get_subtoken_size_ds_based(string)
		}

		if (subtoken_size) {
			token = token substr(string, 1, subtoken_size)
			string = substr(string, subtoken_size + 1)
			subtoken_size = 0
			continue
		}

		# Redirections

		if (match(string, /^([[:digit:]]*[<>]&(-|[[:digit:]]+|[[:digit:]]+-)|[[:digit:]]*(<|>|<<|<>)|&>|<&|<<<|<<-?)(.*)/, temp)) {
			if (length(token)) {
				tokenv[tokenc++] = token
				token = ""
			}

			tokenv[tokenc++] = temp[1]
			string = temp[4]
			continue
		}

		# Digits not followed by redirections

		if (match(string, /^([[:digit:]]+)(.*)/, temp)) {
			token = token temp[1]
			string = temp[2]
			continue
		}

		# Control characters or metacharacters

		if (match(string, /^(\|\||\|&|&&|&\||\||&|;;|;)(.*)/, temp)) {
			if (length(token)) {
				tokenv[tokenc++] = token
				token = ""
			}

			tokenv[tokenc++] = temp[1]
			string = temp[2]
			continue
		}

		# All of the non-special characters or pairs

		if (match(string, /^(#?(\\.?|[^[:blank:][:digit:]"$&';<>|])+)(.*)/, temp)) {
			token = token temp[1]
			string = temp[3]
			continue
		}

		# Compiler bug.  Something was not parsed.

		compiler_log_failure("compiler_get_tokens: Failed to parse string.  This is probably a bug in the parser or the current locale is just not compatible.  String failed to parse was \"" string "\".")
	}

	if (length(token))
		tokenv[tokenc++] = token

	return tokenc
}

function compiler_get_tokens_get_subtoken_size_doublequotes(string,   size, subtoken_size, temp) {
	compiler_log_debug("compiler_get_tokens_get_subtoken_size_doublequotes(\"" string "\")")

	size = 1
	string = substr(string, 2)

	while (length(string)) {
		# Dollar-sign based expansion or substitution

		if (string ~ /^\$/) {
			subtoken_size = compiler_get_tokens_get_subtoken_size_ds_based(string, 1)
			size = size + subtoken_size
			string = substr(string, subtoken_size + 1)
			continue
		}

		# Old backquote command substitution

		if (match(string, /^(`(\\`|[^`])*`?)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[3]
			continue
		}

		# Any non-enclosing pairs or characters

		if (match(string, /^((\\.?|[^"\$`\\])+)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[3]
			continue
		}

		# End of arithmetic expansion

		if (string ~ /^"/) {
			return size + 1
		}

		# Invalid

		compiler_log_failure("compiler_get_tokens_get_subtoken_size_doublequotes: Failed to parse string.  This is probably a bug in the parser or the current locale is just not compatible.  String failed to parse was \"" string "\".")
	}

	compiler_log_failure("compiler_get_tokens_get_subtoken_size_doublequotes: Unexpected end of string while looking for matching '\"'.",
			compiler_walk_current_file, compiler_walk_current_line_number,
			gensub(/^[[:blank:]]+/, "", 1, compiler_walk_current_line))
}

function compiler_get_tokens_get_subtoken_size_ds_based(string, fromdoublequotes,   temp) {
	compiler_log_debug("compiler_get_tokens_get_subtoken_size_ds_based(\"" string "\")")

	# Specialized double quoted strings

	if (!fromdoublequotes && match(string, /^(\$"(\\"|[^"])*"?)/, temp)) {
		return temp[1, "length"]

	# Specialized single quoted strings

	} else if (match(string, /^(\$'(\\'|[^'])*'?)/, temp)) {
		return temp[1, "length"]

	# Arithmetic expansion

	} else if (string ~ /^\$\(\(/) {
		return compiler_get_tokens_get_subtoken_size_ds_based_arithmetic_expansion(string)

	# New command substitution

	} else if (string ~ /^\$\(/) {
		return compiler_get_tokens_get_subtoken_size_ds_based_command_substitution(string)

	# Parameter expansion in braces

	} else if (string ~ /^\$\{/) {
		return compiler_get_tokens_get_subtoken_size_ds_based_parameter_expansion(string)

	# Simple parameter expansions

	} else if (match(string, /^(\$[[:digit:]*@#?\-$!_]|\$[[:alnum:]_]+)/, temp)) {
		return temp[1, "length"]

	# Just an ordinary dollar sign

	} else {
		return 1

	}
}

function compiler_get_tokens_get_subtoken_size_ds_based_arithmetic_expansion(string,   size, subtoken_size, temp) {
	compiler_log_debug("compiler_get_tokens_get_subtoken_size_ds_based_arithmetic_expansion(\"" string "\")")

	size = 3
	string = substr(string, 4)

	while (length(string)) {
		# Another inline dollar-sign based expansion or substitution

		if (string ~ /^\$/) {
			subtoken_size = compiler_get_tokens_get_subtoken_size_ds_based(string)
			size = size + subtoken_size
			string = substr(string, subtoken_size + 1)
			continue
		}

		# Old backquote command substitution

		if (match(string, /^(`(\\`|[^`])*`?)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[3]
			continue
		}

		# Any non-enclosing pairs or characters

		if (match(string, /^((\\.?|[)]?[^$)])+)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[3]
			continue
		}

		# End of arithmetic expansion

		if (string ~ /^\)\)/)
			return size + 1

		# Invalid

		compiler_log_failure("compiler_get_tokens_get_subtoken_size_ds_based_arithmetic_expansion: Failed to parse string.  This is probably a bug in the parser or the current locale is just not compatible.  String failed to parse was \"" string "\".")
	}

	compiler_log_failure("compiler_get_tokens_get_subtoken_size_ds_based_arithmetic_expansion: Unexpected end of string while looking for matching '))'.",
			compiler_walk_current_file, compiler_walk_current_line_number,
			gensub(/^[[:blank:]]+/, "", 1, compiler_walk_current_line))
}

function compiler_get_tokens_get_subtoken_size_ds_based_command_substitution(string,   size, temp) {
	compiler_log_debug("compiler_get_tokens_get_subtoken_size_ds_based_command_substitution(\"" string "\")")

	string = substr(string, 3)

	# Check if there's a comment.

	if (match(string, /^([[:blank:]]*(#[^)]*\)|#[^)]*))/, temp))
		compiler_log_failure("compiler_get_tokens_get_subtoken_size_ds_based_command_substitution: cannot parse comments inside a command substitution enclosure.",
				compiler_walk_current_file, compiler_walk_current_line_number,
				gensub(/^[[:blank:]]+/, "", 1, compiler_walk_current_line))

	size = 2
	subtoken_size = 0

	while (length(string)) {
		# End of enclosure

		if (string ~ /^\)/)
			return size + 1

		# Comments

		if (match(string, /^[[:blank:]]+#/, temp)) {
			compiler_log_failure("compiler_get_tokens_get_subtoken_size_ds_based_command_substitution: Cannot parse comments inside a command substitution enclosure.",
					compiler_walk_current_file, compiler_walk_current_line_number,
					gensub(/^[[:blank:]]+/, "", 1, compiler_walk_current_line))
		}

		# Next token

		if (match(string, /^([[:blank:]]+)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[2]

			if (! length(string))
				break
		}

		# Single quoted strings

		if (match(string, /^('[^']*'?)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[2]
			continue
		}

		# Backquotes (old command substitution)

		if (match(string, /^(`(\\`|[^`])*`?)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[3]
			continue
		}

		# Double quoted strings / dollar-sign based expansions or substitutions

		if (string ~ /^"/) {
			subtoken_size = compiler_get_tokens_get_subtoken_size_doublequotes(string)
		} else if (string ~ /^\$/) {
			subtoken_size = compiler_get_tokens_get_subtoken_size_ds_based(string)
		}

		if (subtoken_size) {
			size = size + subtoken_size
			string = substr(string, subtoken_size + 1)
			subtoken_size = 0
			continue
		}

		# Redirections

		if (match(string, /^([[:digit:]]*[<>]&(-|[[:digit:]]+|[[:digit:]]+-)|[[:digit:]]*(<|>|<<|<>)|&>|<&|<<<|<<-?)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[4]
			continue
		}

		# Digits not followed by redirections

		if (match(string, /^([[:digit:]]+)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[2]
			continue
		}

		# Control characters or metacharacters

		if (match(string, /^(\|\||\|&|&&|&\||\||&|;;|;)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[2]
			continue
		}

		# All of the non-special characters or pairs

		if (match(string, /^(#?(\\.?|[^[:blank:][:digit:]"$&';<>|)])+)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[3]
			continue
		}

		# Compiler bug.  Something was not parsed.

		compiler_log_failure("compiler_get_tokens_get_subtoken_size_ds_based_command_substitution: Failed to parse string.  This is probably a bug in the parser or the current locale is just not compatible.  String failed to parse was \"" string "\".")
	}

	compiler_log_failure("compiler_get_tokens_get_subtoken_size_ds_based_command_substitution: Unexpected end of string while looking for matching ')'.",
			compiler_walk_current_file, compiler_walk_current_line_number,
			gensub(/^[[:blank:]]+/, "", 1, compiler_walk_current_line))
}

function compiler_get_tokens_get_subtoken_size_ds_based_parameter_expansion(string,   size, subtoken_size, temp) {
	compiler_log_debug("compiler_get_tokens_get_subtoken_size_ds_based_parameter_expansion(\"" string "\")")

	size = 2
	string = substr(string, 3)

	while (length(string)) {
		# Inline single quoted strings.

		if (match(string, /^('[^']+'?)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[2]
			continue
		}

		# Old backquote command substitution

		if (match(string, /^(`(\\`|[^`])*`?)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[3]
			continue
		}

		# Double quotes

		if (string ~ /^\"/) {
			subtoken_size = compiler_get_tokens_get_subtoken_size_doublequotes(string)
			size = size + subtoken_size
			string = substr(string, subtoken_size + 1)
			continue
		}

		# Another inline dollar-sign based expansion or substitution

		if (string ~ /^\$/) {
			subtoken_size = compiler_get_tokens_get_subtoken_size_ds_based(string)
			size = size + subtoken_size
			string = substr(string, subtoken_size + 1)
			continue
		}

		# Any non-enclosing pairs or characters

		if (match(string, /^((\\.?|[^"$'\\}])+)(.*)/, temp)) {
			size = size + temp[1, "length"]
			string = temp[3]
			continue
		}

		# End of parameter expansion

		if (string ~ /^\}/)
			return size + 1

		# Invalid

		compiler_log_failure("compiler_get_tokens_get_subtoken_size_ds_based_parameter_expansion: Failed to parse string.  This is probably a bug in the parser or the current locale is just not compatible.  String failed to parse was \"" string "\".")
	}

	compiler_log_failure("compiler_get_tokens_get_subtoken_size_ds_based_parameter_expansion: Unexpected end of string while looking for matching '))'.",
			compiler_walk_current_file, compiler_walk_current_line_number,
			gensub(/^[[:blank:]]+/, "", 1, compiler_walk_current_line))
}

function compiler_get_working_dir(  cmd, wd) {
	compiler_log_debug("compiler_get_working_dir()")

	cmd = "pwd"

	if ((cmd | getline wd) > 0) {
		close(cmd)
		return wd
	} else {
		close(cmd)
		return ""
	}
}

function compiler_log_debug(text) {
	if (compiler_debug_mode)
		compiler_log_message(text)
}

function compiler_log_failure(text, file, line_no, context) {
	compiler_log_message("Failure: " text, file, line_no, context)
	exit(1)
}

function compiler_log_message(text, file, line_no, context) {
	if (file) {
		if (context)
			text = context ":\n\t" text
		if (line_no)
			text = "line " line_no ": " text
		text = file ": " text
	}
	print "compiler: " text > "/dev/stderr"
}

function compiler_log_warning(text, file, line_no, context) {
	compiler_log_message("warning: " text, file, line_no, context)
}

function compiler_log_stderr(text) {
	print text >"/dev/stderr"
}

function compiler_make_hash(string, hash_length,   randomizer, hash, hash_string, string_length, sum, c, h, i, n, r, s) {
	if (!hash_length || hash_length <= 0)
		hash_length = compiler_make_hash_default_hash_length

	string = "hash" string
	string_length = length(string)
	randomizer = 2.86
	number_margin = 2 ^ 16

	sum = 0

	for (s = 1; s <= string_length; ++s) {
		c = substr(string, s, 1)
		sum = (sum + compiler_make_hash_itable[c]) % number_margin
	}

	n = sum
	h = 0

	for (s = 1; s <= string_length; ++s) {
		c = substr(string, s, 1)
		n = n + compiler_make_hash_itable[c]

		for (i = 1; i <= hash_length; ++i) {
			n = hash[h] + n
			r = (n * randomizer + randomizer) % (10 + 26)
			hash[h++] = r
			h = h % hash_length
			n = n - r
		}

		n = n % number_margin
	}

	hash_string = ""

	for (h = 0; h < hash_length; ++h) {
		n = int(hash[h])
		hash_string = hash_string compiler_make_hash_ctable[n]
	}

	return hash_string
}

function compiler_make_hash_initialize(uppercase, default_hash_length,   c, i, j, l, h) {
	if (uppercase) {
		l = 65
		h = 92
	} else {
		l = 97
		h = 122
	}

	j = 0

	for (i = 0; i <= 255; ++i) {
		c = sprintf("%c", i)

		compiler_make_hash_itable[c] = i

		if ((i >= 48 && i <= 57) || (i >= l && i <= h)) {
			compiler_make_hash_ctable[j++] = c
		}
	}

	compiler_make_hash_default_hash_length = default_hash_length
}

function compiler_remove_file(file) {
	compiler_log_message("remove file: " file)
	return (system("rm '" file "' >/dev/null 2>&1") == 0)
}

function compiler_remove_quotes(string,   temp) {
	if (match(string, /^'(.*)'$/, temp))
		return temp[1]

	if (match(string, /^"(.*)"$/, temp))
		string = temp[1]

	return gensub(/\\(.)/, "\\1", "g", string)
}

function compiler_test(op, file) {
	file = compiler_gen_doublequotes_form(file)
	return (system("test " op " " file " >/dev/null 2>&1") == 0)
}

function compiler_truncate_file(file) {
	compiler_log_message("truncate: " file)
	return (system(": > '" file "' >/dev/null 2>&1") == 0)
}

function compiler_write_to_calls_obj(text) {
	print text >> compiler_calls_obj_file
}

function compiler_write_to_calls_obj_comment(text) {
	if (!compiler_no_info) {
		sub(/^(  )?/, "#:", text)
		print text >> compiler_calls_obj_file
	}
}

function compiler_write_to_main_obj(text) {
	print text >> compiler_main_obj_file
}

function compiler_write_to_main_obj_comment(text) {
	if (!compiler_no_info) {
		sub(/^(  )?/, "#:", text)
		print text >> compiler_main_obj_file
	}
}


# Extensions

function EXTENSIONS(  i) {
	ARGS = "\"" gensub(/"/, "\\\"", "g", ARGV[1]) "\""

	for (i = 2; i < ARGC; ++i)
		ARGS = ARGS gensub(/"/, "\\\"", "g", ARGV[i])
}


# Begin

BEGIN {
	GLOBALS()
	EXTENSIONS()
	compiler()
}
