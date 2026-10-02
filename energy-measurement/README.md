# Energy measurement, release 2021.06.06

Instrumentation for measuring the energy consumed by this project's CI cell at
tag `2021.06.06` (`b224cf39d53bd16bcfda2ac493712c3ff449ecb8`). Branch `release-2021.06.06` is the tag plus one commit that
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

The tag has a single workflow, `.github/workflows/ci.yml`, whose `tests` job runs
a matrix. The measured cell is **`ubuntu-18.04 / cpython / 3.9 / core`**, the same
cell as the HEAD campaign of this fork with the Python line the tag supports:

- **3.9** is the highest CPython of the tag's matrix (`ci.yml:12`); the HEAD
  campaign measures 3.11, which the tag does not list. The patch, 3.9.5, is the
  latest 3.9 release on the tag date.
- **`core`** is the offline half of the suite: `devscripts/run_tests.sh:4` lists
  the download tests and its comment points at the `offlinetest` target of the
  `Makefile`, which carries the same list. The `download` set needs the network.

The `flake8` job is a linter, not a build or a test, and is out of scope.

## Stages

| stage | commands | source |
|---|---|---|
| `build` | `pip install nose` | `ci.yml:55-57` |
| `test` | `./devscripts/run_tests.sh` with `YTDL_TEST_SET=core` | `ci.yml:66-67`, `ci.yml:68` |

The project builds nothing in CI. The `build` stage is environment preparation,
as in the HEAD campaign.

Every command in `commands.sh` is literal. The one difference against the
workflow:

| # | difference | why |
|---|---|---|
| D-7 | the `build` stage installs into a throwaway virtualenv | each stage runs in its own `--rm` container, so the image carries the runner for `test`; without a fresh environment the literal install would find nose already present |

## Running

```
docker build -t youtube-dl-measurement-2021.06.06 -f energy-measurement/Dockerfile .
gh workflow run energy-measurement.yml --ref release-2021.06.06 -f campaign=validation
gh workflow run energy-measurement.yml --ref release-2021.06.06 -f campaign=full
```

`validation` runs run 0 only. `full` runs a discarded warm-up plus runs 1..10 and
writes the medians. Host swap counters and package temperature are read outside
each stage's energy window and stored as `swap_run_NN_<stage>.txt` and
`temp_run_NN_<stage>.txt`.

## Network

Both stages run under `--network none`. nose is resolved at image build time
into `/wheels`, pinned by version and sha256, and the measured `pip install`
reads from there (`PIP_NO_INDEX=1`, `PIP_FIND_LINKS=/wheels`). The HTTP tests of
the `core` set bind `127.0.0.1`, which loopback satisfies.
