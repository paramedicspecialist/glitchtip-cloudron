FROM glitchtip/glitchtip:6.2.6

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends bash ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

ARG GOSU_VERSION=1.17
RUN arch="$(dpkg --print-architecture)" \
    && curl -fsSL -o /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${arch}" \
    && chmod 755 /usr/local/bin/gosu \
    && gosu nobody true

COPY start.sh configure.py /app/pkg/
COPY cloudron_hook.py /tmp/cloudron_hook.py
RUN python - <<'PY'
import pathlib
import shutil
import site

dest = pathlib.Path(site.getsitepackages()[0])
shutil.copy("/tmp/cloudron_hook.py", dest / "cloudron_hook.py")
(dest / "cloudron_glitchtip.pth").write_text("import cloudron_hook\n")
PY
RUN chmod 755 /app/pkg/start.sh \
    && chmod 644 /app/pkg/configure.py

WORKDIR /code
ENTRYPOINT ["/app/pkg/start.sh"]
