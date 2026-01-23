#!/usr/bin/env bash
#
# test_runner.sh - Simple test harness
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/test_ini.sh"
