#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Delete Saved Chrome Tab Groups.app"

echo "Compiling AppleScript into macOS App: ${APP_NAME}..."
osacompile -o "${APP_NAME}" delete_saved_tab_groups.applescript

echo "Done! Generated '${APP_NAME}'."
