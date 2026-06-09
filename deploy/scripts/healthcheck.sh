#!/bin/sh
set -euo pipefail
squidclient -h localhost mgr:info > /dev/null 2>&1
exit $?
