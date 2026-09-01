#!/usr/bin/env bash
# lib/loader.sh — discover and source modules.
#
# LAZY_MODULES=git,docker  → load only those
# unset / empty            → load every modules/*/ directory

lazy_load_modules() {
  local modules_dir="${LAZY_ROOT}/modules"
  local wanted="${LAZY_MODULES:-}"
  local dir name file

  for dir in "${modules_dir}"/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"

    # Skip if user asked for a subset and this domain isn't in it.
    if [ -n "$wanted" ]; then
      case ",${wanted}," in
        *",${name},"*) ;;
        *) continue ;;
      esac
    fi

    file="${dir}${name}.sh"
    if [ -f "$file" ]; then
      # shellcheck source=/dev/null
      . "$file"
    fi
  done
}
