#!/bin/bash
set -euo pipefail

cd /code

data_dir="/app/data"
media_dir="${data_dir}/media"
secret_file="${data_dir}/secret_key"
mkdir -p "${media_dir}"

if [[ ! -s "${secret_file}" ]]; then
    python -c 'import secrets; print(secrets.token_urlsafe(50), end="")' > "${secret_file}"
    chmod 600 "${secret_file}"
fi

if id app >/dev/null 2>&1; then
    chown -R app:app "${data_dir}"
    run_as=(gosu app)
else
    run_as=()
fi

export SECRET_KEY
SECRET_KEY="$(<"${secret_file}")"
export GLITCHTIP_EMBED_WORKER=true
export ENABLE_USER_REGISTRATION=false
export ENABLE_ORGANIZATION_CREATION=false
export MEDIA_ROOT="${media_dir}"
export DUCKDB_TEMP_DIRECTORY="${DUCKDB_TEMP_DIRECTORY:-/tmp}"
export VTASKS_CONCURRENCY="${VTASKS_CONCURRENCY:-4}"
export DATABASE_POOL_MAX_SIZE="${DATABASE_POOL_MAX_SIZE:-5}"
export GRANIAN_WORKERS="${GRANIAN_WORKERS:-1}"
export GRANIAN_WORKERS_MAX_RSS="${GRANIAN_WORKERS_MAX_RSS:-512}"
export DJANGO_SETTINGS_MODULE="${DJANGO_SETTINGS_MODULE:-glitchtip.settings}"

if [[ -n "${CLOUDRON_APP_ORIGIN:-}" ]]; then
    export GLITCHTIP_DOMAIN="${CLOUDRON_APP_ORIGIN}"
    export CSRF_TRUSTED_ORIGINS="${CLOUDRON_APP_ORIGIN}"
fi
if [[ -n "${CLOUDRON_APP_DOMAIN:-}" ]]; then
    export ALLOWED_HOSTS="${CLOUDRON_APP_DOMAIN}"
fi
if [[ -n "${CLOUDRON_POSTGRESQL_URL:-}" ]]; then
    export DATABASE_URL="${CLOUDRON_POSTGRESQL_URL}"
fi
if [[ -n "${CLOUDRON_REDIS_URL:-}" ]]; then
    export VALKEY_URL="${CLOUDRON_REDIS_URL}"
fi

if [[ -n "${CLOUDRON_MAIL_SMTP_SERVER:-}" ]]; then
    EMAIL_URL="$(python - <<'PY'
import os
from urllib.parse import quote

user = quote(os.environ.get("CLOUDRON_MAIL_SMTP_USERNAME", ""), safe="")
password = quote(os.environ.get("CLOUDRON_MAIL_SMTP_PASSWORD", ""), safe="")
host = os.environ["CLOUDRON_MAIL_SMTP_SERVER"]
port = os.environ.get("CLOUDRON_MAIL_SMTP_PORT", "25")
print(f"smtp://{user}:{password}@{host}:{port}", end="")
PY
)"
    export EMAIL_URL
    export DEFAULT_FROM_EMAIL="${CLOUDRON_MAIL_FROM:?CLOUDRON_MAIL_FROM is required when mail is configured}"
else
    export EMAIL_URL="${EMAIL_URL:-consolemail://}"
    export DEFAULT_FROM_EMAIL="${DEFAULT_FROM_EMAIL:-webmaster@localhost}"
fi

oidc_ready=false
if [[ -n "${CLOUDRON_OIDC_CLIENT_ID:-}" && -n "${CLOUDRON_OIDC_CLIENT_SECRET:-}" && -n "${CLOUDRON_OIDC_DISCOVERY_URL:-}" ]]; then
    oidc_ready=true
fi
if [[ "${oidc_ready}" == "true" ]]; then
    export ENABLE_SOCIAL_APPS_USER_REGISTRATION=true
else
    export ENABLE_SOCIAL_APPS_USER_REGISTRATION=false
fi

if [[ -z "${DATABASE_URL:-}" ]]; then
    echo "DATABASE_URL is not set. On Cloudron this comes from the PostgreSQL addon." >&2
    exit 1
fi
if [[ -n "${CLOUDRON_APP_DOMAIN:-}" && -z "${VALKEY_URL:-}" ]]; then
    echo "VALKEY_URL is not set. On Cloudron this comes from the Redis addon." >&2
    exit 1
fi

echo "startup domain=${CLOUDRON_APP_DOMAIN:-unset} oidc=${oidc_ready}"

"${run_as[@]}" python /app/pkg/configure.py
export SKIP_INIT=true
exec "${run_as[@]}" ./bin/start.sh
