#!/usr/bin/env bash

set -euo pipefail
STAGE="${1:?stage required: build | test}"

# Every stage runs from the repository root, as the upstream job does: the test
# runner resolves the test package and devscripts/ from the working directory.
cd /workspace

# Matrix values of the measured cell, standing in for the GitHub expressions the
# upstream job expands: python-version 3.11, python-impl cpython, run-tests-ext sh.
PYTHON_VERSION=3.11
PYTHON_IMPLEMENTATION=cpython

case "$STAGE" in

  # ci.yml:362-368, 411-418
  build)
    # The image already carries the test runner, because the test stage runs in
    # its own --rm container and cannot see what this one installs. Without a
    # fresh environment `pip show` would short-circuit the literal install, so
    # the stage measures a real installation in a throwaway virtualenv (D-7).
    python -m venv /tmp/venv-build
    # shellcheck disable=SC1091
    . /tmp/venv-build/bin/activate

    echo "$PATH"
    echo "$PYTHONHOME"
    # curl is available on both Windows and Linux, -L follows redirects, -O gets name
    # get_pip is empty for 3.11: own-pip-versions covers 2.6 to 3.6 only (ci.yml:103),
    # and ensurepip succeeds here, so the curl branch is never taken.
    python -m ensurepip || python -m pip --version || { \
      get_pip=""; \
      curl -L -O "https://bootstrap.pypa.io/pip/${get_pip}get-pip.py"; \
      python get-pip.py --no-setuptools --no-wheel; }

    echo "$PATH"
    echo "$PYTHONHOME"
    # Use PyNose for recent Pythons instead of Nose
    py3ver="$PYTHON_VERSION"
    py3ver=${py3ver#3.}
    [ "$py3ver" != "$PYTHON_VERSION" ] && py3ver=${py3ver%.*} || py3ver=0
    [ "$py3ver" -ge 9 ] && nose=pynose || nose=nose
    $PIP -qq show $nose || $PIP install $nose
    ;;

  # ci.yml:438-460, 468
  test)
    # set PYTHON_VER
    PYTHON_VER=$PYTHON_VERSION
    [ "${PYTHON_VER#*-}" != "$PYTHON_VER" ] || PYTHON_VER="$PYTHON_IMPLEMENTATION-${PYTHON_VER}"
    # The upstream step exports these through GITHUB_ENV, which no container has.
    export PYTHON_VER
    export PYTHON_IMPL="$PYTHON_IMPLEMENTATION"
    # define a test to validate the Python version used by nosetests
    # The build stage runs in its own --rm container, so this file is written here.
    printf '%s\n' \
      'from __future__ import unicode_literals' \
      'import sys, os, platform' \
      'try:' \
      '    import unittest2 as unittest' \
      'except ImportError:' \
      '    import unittest' \
      'class TestPython(unittest.TestCase):' \
      '    def setUp(self):' \
      '        self.ver = os.environ["PYTHON_VER"].split("-")' \
      '    def test_python_ver(self):' \
      '        self.assertEqual(["%d" % v for v in sys.version_info[:2]], self.ver[-1].split(".")[:2])' \
      '        self.assertTrue(sys.version.startswith(self.ver[-1]))' \
      '        self.assertIn(self.ver[0], ",".join((sys.version, platform.python_implementation())).lower())' \
      '    def test_python_impl(self):' \
      '        self.assertIn(platform.python_implementation().lower(), (os.environ["PYTHON_IMPL"], self.ver[0]))' \
      > test/test_python.py

    ./devscripts/run_tests.sh
    ;;

  *)
    echo "unknown stage: $STAGE" >&2
    exit 2
    ;;

esac
