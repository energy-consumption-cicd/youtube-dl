#!/usr/bin/env bash

set -euo pipefail
STAGE="${1:?stage required: build | test}"

# Every stage runs from the repository root, as the upstream job does: the test
# runner resolves the test package and devscripts/ from the working directory.
cd /workspace

# Measured cell at tag 2021.06.06: ubuntu-18.04 / cpython 3.9 / core / sh.

case "$STAGE" in

  # ci.yml:57
  build)
    # The image already carries the test runner, because the test stage runs in
    # its own --rm container and cannot see what this one installs. Without a
    # fresh environment the literal install would find nose already present, so
    # the stage measures a real installation in a throwaway virtualenv (D-7).
    python -m venv /tmp/venv-build
    # shellcheck disable=SC1091
    . /tmp/venv-build/bin/activate

    pip install nose
    ;;

  # ci.yml:68
  test)
    ./devscripts/run_tests.sh
    ;;

  *)
    echo "unknown stage: $STAGE" >&2
    exit 2
    ;;

esac
