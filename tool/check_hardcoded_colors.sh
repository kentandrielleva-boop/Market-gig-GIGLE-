#!/usr/bin/env sh
# Fails if hardcoded Color(0x..) / Colors.* appear outside lib/core/theme/.
# Run from the repo root: sh tool/check_hardcoded_colors.sh
set -eu
dart tool/check_hardcoded_colors.dart
