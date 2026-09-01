#!/usr/bin/env bash
# lazy — entrypoint
# source this from bash or zsh. loads config + modules.

# Resolve absolute directory of this file (bash + zsh).
if [ -n "${BASH_SOURCE[0]:-}" ]; then
  LAZY_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [ -n "${ZSH_VERSION:-}" ]; then
  LAZY_ROOT="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
  LAZY_ROOT="$(cd "$(dirname "$0")" && pwd)"
fi

export LAZY_ROOT

# Core libraries (order matters).
# shellcheck source=/dev/null
. "${LAZY_ROOT}/lib/core.sh"
# shellcheck source=/dev/null
. "${LAZY_ROOT}/lib/config.sh"
# shellcheck source=/dev/null
. "${LAZY_ROOT}/lib/loader.sh"

lazy_load_config
lazy_load_modules

if lazy_truthy "${LAZY_UNALIAS:-false}"; then
  lazy_unalias_all
fi
