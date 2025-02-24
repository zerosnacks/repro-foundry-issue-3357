#!/usr/bin/env bash

# Exit if anything fails
set -euo pipefail

# Change directory to project root
SCRIPT_PATH="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_PATH/.." || exit

# Check for http-server dependency
if ! [ -x "$(command -v http-server)" ]; then
  echo 'Error: http-server is not installed. (npm install -g http-server)' >&2
  exit 1
fi

# Start both HTTP servers in the background
http-server reports/coverage/default -o -c-1 -p 3000 &
PID1=$!

http-server reports/coverage/ir-minimum -o -c-1 -p 3001 &
PID2=$!

# Function to handle script exit
cleanup() {
    echo "Stopping servers..."
    kill $PID1 $PID2
    wait $PID1 $PID2 2>/dev/null
    echo "Servers stopped."
}

# Trap signals and call cleanup function
trap cleanup EXIT

# Wait for both processes
wait $PID1 $PID2

log $GREEN "Done"