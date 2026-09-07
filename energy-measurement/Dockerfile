# The test runner is resolved and cached at image build time so the measured
# stages can run with --network none.
FROM python@sha256:35d3a4a3d5e42e02ab916d44513a050689f12c0533d45598d229672503fe77ca

# Frozen on the image build date; the upstream command installs it unpinned.
ARG PYNOSE_VERSION=1.5.5
ARG PYNOSE_SHA256=673751d53fcfc79b1e48c14f36c7a24779ad43676eeb85736934de6a2b3d8ec8

# pynose has no dependencies, so a single hashed requirement pins the whole set.
RUN set -eux; \
    printf '%s\n' "pynose==${PYNOSE_VERSION} --hash=sha256:${PYNOSE_SHA256}" > /tmp/req.txt; \
    python -m pip download --disable-pip-version-check --require-hashes --no-deps \
      -r /tmp/req.txt -d /wheels; \
    python -m pip install --disable-pip-version-check --no-index --find-links=/wheels \
      "pynose==${PYNOSE_VERSION}"; \
    rm -f /tmp/req.txt; \
    python -m pip show pynose

# The Chromium-style constraint does not apply here, but the hosted runner does
# not run as root either, and the suite writes into the checkout.
RUN useradd -m -u 1000 runner

COPY --chown=runner:runner . /workspace
WORKDIR /workspace
USER runner

# PIP is the variable the upstream job defines for the measured commands
# (ci.yml:113-115); the offline settings replace the network index (D-1).
ENV PIP="python -m pip" \
    PIP_NO_INDEX=1 \
    PIP_FIND_LINKS=/wheels \
    PIP_DISABLE_PIP_VERSION_CHECK=true \
    PIP_NO_PYTHON_VERSION_WARNING=true

# Injected by the upstream step as a step-level env (ci.yml:465-466).
ENV YTDL_TEST_SET=core
