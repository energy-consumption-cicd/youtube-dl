# Energy measurement

Instrumentation for measuring the energy consumed by this project's CI cell. It
adds five files and modifies none of the upstream tree.

```
.github/workflows/energy-measurement.yml
energy-measurement/
├── README.md
├── Dockerfile
├── run_pipeline.sh
└── commands.sh
```

## Measured cell

The repository has a single workflow, `.github/workflows/ci.yml`, whose `tests`
job runs a matrix. The measured cell is **`ubuntu-22.04 / cpython / 3.11 / core`**:

- **3.11** is the highest of `main-cpython-versions` (`ci.yml:5`), the subset the
  project designates as primary for pull requests.
- **`core`** is what the CI runs on push (`ci.yml:68-69`). It is the offline half
  of the suite: `devscripts/run_tests.sh:4` lists the download tests and its
  comment points at the `offlinetest` target of the `Makefile`, which carries the
  same list.

The `flake8` job is a linter, not a build or a test, and is out of scope.

## Stages

| stage | commands | source |
|---|---|---|
| `build` | pip bootstrap, then `pip install pynose` | `ci.yml:362-368`, `ci.yml:411-418` |
| `test` | generate `test/test_python.py`, then `./devscripts/run_tests.sh` | `ci.yml:438-460`, `ci.yml:468` |

The project builds nothing in CI: the `Makefile` build targets (`Makefile:1,60`)
are never invoked by the workflow. The `build` stage is therefore environment
preparation, as in other Python projects of the study.

Every command in `commands.sh` is literal. The differences against the workflow
are these, and no others:

| # | difference | why |
|---|---|---|
| - | GitHub expressions expanded (`matrix.python-version`, `matrix.python-impl`, `matrix.run-tests-ext`, the `own-pip-versions` test that selects the get-pip URL) | the runner expands them; the measured cell fixes them |
| - | the two `GITHUB_ENV` writes become `export` | a container has no `GITHUB_ENV` |
| D-7 | the `build` stage installs into a throwaway virtualenv | each stage runs in its own `--rm` container, so the image carries the runner for `test`; without a fresh environment `pip show` would short-circuit the literal install |
| D-8 | the two `echo "$PYTHONHOME"` lines are omitted (`ci.yml:363`, `ci.yml:412`) | `PYTHONHOME` is produced by `Locate supported Python` (`ci.yml:169-200`), a runner-setup step outside the measured construct; the interpreter comes from the base image instead. Setting it in the container would override `sys.prefix` and defeat D-7. Energy effect: none, two `echo` lines |

## Running

Each stage runs in its own container, so the image carries the test runner for
the `test` stage and the `build` stage reinstalls it in a throwaway virtualenv;
otherwise `pip show` would short-circuit the literal install.

```
docker build -t youtube-dl-medicao -f energy-measurement/Dockerfile .
gh workflow run energy-measurement.yml -f campaign=validation
gh workflow run energy-measurement.yml -f campaign=full
```

`validation` runs run 0 only. `full` runs a discarded warm-up plus runs 1..10 and
writes the medians.

## Network

Both stages run under `--network none`. The test runner is resolved at image
build time into `/wheels`, pinned by version and sha256, and the measured
`pip install` reads from there (`PIP_NO_INDEX=1`, `PIP_FIND_LINKS=/wheels`). The
HTTP tests of the `core` set bind `127.0.0.1`, which loopback satisfies.
