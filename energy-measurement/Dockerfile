# Release 2021.06.06 (b224cf39d53bd16bcfda2ac493712c3ff449ecb8): same cell as the HEAD campaign, python-version 3.9.
# The test runner is resolved and cached at image build time so the measured
# stages can run with --network none.
# python:3.9.5-buster, the latest 3.9 patch on the tag date; the tag's CI tops out at 3.9.
FROM python@sha256:bb738a13e61033430204bc70344a87f4db911c024bb5374d71dd94646ac46d67

# nose 1.3.7 is the last nose release (2015), so the unpinned upstream install
# resolves to it on any date; nose has no dependencies.
ARG NOSE_VERSION=1.3.7
ARG NOSE_SHA256=9ff7c6cc443f8c51994b34a667bbcf45afd6d945be7477b52e97516fd17c53ac

RUN set -eux; \
    printf '%s\n' "nose==${NOSE_VERSION} --hash=sha256:${NOSE_SHA256}" > /tmp/req.txt; \
    python -m pip download --disable-pip-version-check --require-hashes --no-deps \
      -r /tmp/req.txt -d /wheels; \
    python -m pip install --disable-pip-version-check --no-index --find-links=/wheels \
      "nose==${NOSE_VERSION}"; \
    rm -f /tmp/req.txt; \
    python -m pip show nose

# The Chromium-style constraint does not apply here, but the hosted runner does
# not run as root either, and the suite writes into the checkout.
RUN useradd -m -u 1000 runner

COPY --chown=runner:runner . /workspace
WORKDIR /workspace
USER runner

# The offline settings replace the network index (D-1).
ENV PIP_NO_INDEX=1 \
    PIP_FIND_LINKS=/wheels \
    PIP_DISABLE_PIP_VERSION_CHECK=true \
    PIP_NO_PYTHON_VERSION_WARNING=true

# Injected by the upstream step as a step-level env (ci.yml:66-67 at the tag).
ENV YTDL_TEST_SET=core
