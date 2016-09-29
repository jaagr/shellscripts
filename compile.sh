#!/usr/bin/env bash
# TODO: support nested [post-pass:] blocks

function main
{
  exec >&2

  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <input> <output> [compiler_flags...]"; exit 1
  fi

  local compiler="${SHELLSCRIPTLOADER_COMPILER:-$(dirname "$0")/contrib/shellscriptloader-0.1.1/compiler}"

  if ! [[ -e "$compiler" ]]; then
    echo "error: Compiler script \"$compiler\" does not exist. Specify path using SHELLSCRIPTLOADER_COMPILER"; exit 2
  fi

  local input="$1"; shift
  local output="$1"; shift
  local flags=""

  while [[ $# -gt 0 ]]; do
    flags="$flags $1"; shift
  done

  cp "$input" "$output"

  echo "pre-pass: replace alias fn (bootstrap::finish -> loader_finish)"
  sed -i 's/bootstrap::finish/loader_finish/' "$output"

  local execline="gawk -f $compiler --$flags -o ${output}.out $output"
  echo "$execline"
  eval "$execline"

  mv "${output}.out" "$output"

  if [[ $? -eq 0 ]]; then
    chmod +x "$output"
  fi

  IFS=$'\n'

  local -i pass=0

  # remove unused function definitions
  while (( pass++ <= 5 ))
  do
    local fn_name unused_fn inside_fn
    local -i line_no=0 unused_line_start=0

    cp "$output" "${output}.min"

    # shellcheck disable=2094
    while read -r line; do
      let line_no++

      # check for function body close tag
      if $inside_fn; then
        if [[ "$line" == "}" ]]; then
          inside_fn='false'

          # remove function body
          if [[ "$unused_fn" ]]; then
            echo "post-pass #${pass}: Removing unused function '$unused_fn' (lines ${unused_line_start}-${line_no})"
            sed -i "${unused_line_start},${line_no}s/.*//" "${output}.min"
            unset unused_fn
          fi
        fi

        continue
      fi

      # check for function body open statement
      fn_name=$(sed -nr 's/^function ([^ ]+) ?\{?$/\1/p' <<< "$line")

      if ! [[ "$fn_name" ]]; then
        continue
      fi

      inside_fn='true'

      # check for any occurrences of fn_name other than the definition
      if ! grep -v "function $fn_name" "${output}.min" | egrep -q "( |trap .*|\(|\`|\||^)${fn_name}( |\)|\`|'|\||;|>|$)"; then
        unused_fn="$fn_name"
        unused_line_start=$line_no
      fi
    done < "$output"

    mv "${output}.min" "$output"
  done

  cp "$output" "${output}.min"

  # remove code blocks that depends on unused functions
  #   test '[post-pass:require-fn=log::defer]'
  #   ....
  #   test '[/post-pass]'
  local -i line_no=0 block_start=0
  local require_fn

  while read -r line; do
    let line_no++

    if [[ "$line" == "test '[/post-pass:require-fn]'" ]]; then
      if [[ $block_start -gt 0 ]]; then
        echo "post-pass: Removing code block depending on '${require_fn}' (lines ${block_start}-${line_no})"
        sed -i "${block_start},${line_no}s/.*//" "${output}.min"
        let block_start=0
      else
        sed -i "${line_no}s/.*//" "${output}.min"
      fi
      continue
    elif [[ $block_start -gt 0 ]]; then
      continue
    fi

    require_fn=$(sed -nr 's/test .\[post-pass:require-fn=(.*)\]/\1/p' <<< "$line" | tr -d "'")

    if ! [[ "$require_fn" ]]; then
      continue
    fi

    # look for the function body
    if egrep -q "function[ ]*$require_fn" "${output}.min"; then
      sed -i "${line_no}s/.*//" "${output}.min"
    else
      let block_start=line_no
    fi
  done < "$output"

  mv "${output}.min" "$output"

  # Strip bootstrap
  sed -r -i '/source[ ]+bootstrap.sh/d' "$output"

  # Strip consecutive blank lines
  # sed -i 'N; /^\n$/d; P; D' "$output"

  # Strip blank lines
  sed -i '/^$/d' "$output"
}

main "$@"
