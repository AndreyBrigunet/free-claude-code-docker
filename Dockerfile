# syntax=docker/dockerfile:1.7

FROM python:3.14-slim AS runtime

ARG FCC_REPOSITORY=https://github.com/Alishahryar1/free-claude-code.git
ARG FCC_REF=main

LABEL org.opencontainers.image.title="Free Claude Code Docker"
LABEL org.opencontainers.image.description="Container image for Free Claude Code (FCC) built from upstream source"
LABEL org.opencontainers.image.source="https://github.com/Alishahryar1/free-claude-code"
LABEL org.opencontainers.image.licenses="MIT"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    HOME=/root \
    HOST=0.0.0.0 \
    PORT=8082 \
    FCC_OPEN_BROWSER=false \
    MESSAGING_PLATFORM=none \
    VOICE_NOTE_ENABLED=false

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*

RUN python -m pip install --no-cache-dir --upgrade pip \
    && python -m pip install --no-cache-dir uv

WORKDIR /tmp/fcc

RUN git init \
    && git remote add origin "${FCC_REPOSITORY}" \
    && git fetch --depth 1 origin "${FCC_REF}" \
    && git checkout --detach FETCH_HEAD \
    && printf '%s\n' "$(git rev-parse HEAD)" > /usr/local/share/fcc-upstream-commit \
    && uv pip install --system . \
    && cd / \
    && rm -rf /tmp/fcc /root/.cache

WORKDIR /app

EXPOSE 8082

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8082/health', timeout=3).read()" || exit 1

CMD ["fcc-server"]
