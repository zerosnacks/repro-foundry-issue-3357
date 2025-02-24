#!/usr/bin/env bash

# Exit if anything fails
set -euo pipefail

# Change directory to project root
SCRIPT_PATH="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"
cd "$SCRIPT_PATH/.." || exit

# Utilities
GREEN="\033[00;32m"

function log () {
  echo -e "$1"
  echo "################################################################################"
  echo "#### $2 "
  echo "################################################################################"
  echo -e "\033[0m"
}

# Default settings
VERBOSITY_LEVEL=5

# Check for lcov dependency
if ! [ -x "$(command -v genhtml)" ]; then
  echo 'Error: lcov is not installed. (sudo apt install lcov)' >&2
  exit 1
fi

# Check for http-server dependency
if ! [ -x "$(command -v http-server)" ]; then
  echo 'Error: http-server is not installed. (npm install -g http-server)' >&2
  exit 1
fi

# Set Foundry environment variables
export FOUNDRY_DISABLE_NIGHTLY_WARNING=true

log $GREEN "Creating coverage reports"

# Create directory
mkdir -p reports

# Generate coverage report
forge coverage --report lcov --lcov-version 2.0.1

# Generate HTML report from coverage report
genhtml --branch-coverage -o reports/coverage/default lcov.info

cp lcov.info default-lcov.info

# Generate coverage report
forge coverage --ir-minimum --report lcov --lcov-version 2.0.1

# Generate HTML report from coverage report
genhtml --branch-coverage -o reports/coverage/ir-minimum lcov.info

cp lcov.info ir-minimum-lcov.info

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