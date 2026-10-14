#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "${root}"

api_url="${GLITCHTIP_TAGS_URL:-https://gitlab.com/api/v4/projects/glitchtip%2Fglitchtip-backend/repository/tags?order_by=version&sort=desc&per_page=50}"
image_repo="glitchtip/glitchtip"

latest="$(curl -fsSL -H "User-Agent: glitchtip-cloudron" "${api_url}" | python3 -c '
import json
import re
import sys

tags = json.load(sys.stdin)
if not isinstance(tags, list):
    raise SystemExit("GitLab did not return a tag list")

pattern = re.compile(r"^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$")
best = None
for tag in tags:
    name = tag.get("name") or ""
    match = pattern.fullmatch(name)
    if not match:
        continue
    parts = tuple(int(part) for part in match.groups())
    version = ".".join(match.groups())
    if best is None or parts > best[0]:
        best = (parts, version)

if best is None:
    raise SystemExit("GitLab did not return a stable GlitchTip tag")
print(best[1])
')"

if [[ ! "${latest}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Refusing non-semver GlitchTip tag: ${latest}" >&2
    exit 1
fi

current="$(sed -n 's/^FROM glitchtip\/glitchtip:\([0-9.]*\)$/\1/p' Dockerfile)"
if [[ -z "${current}" ]]; then
    echo "Could not read the pinned GlitchTip version from Dockerfile" >&2
    exit 1
fi

write_output() {
    local name="$1"
    local value="$2"
    echo "${name}=${value}"
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "${name}=${value}" >> "${GITHUB_OUTPUT}"
    fi
}

upstream_image_published() {
    local tag="$1"
    local code
    code="$(curl -sS -o /dev/null -w '%{http_code}' \
        -H "User-Agent: glitchtip-cloudron" \
        "https://hub.docker.com/v2/repositories/${image_repo}/tags/${tag}")"
    if [[ "${code}" == "200" ]]; then
        return 0
    fi
    if [[ "${code}" == "404" ]]; then
        return 1
    fi
    echo "Could not check ${image_repo}:${tag} (HTTP ${code})" >&2
    exit 1
}

if [[ "${current}" == "${latest}" && "${FORCE_BUMP:-}" != "true" ]]; then
    echo "Already at GlitchTip ${latest}"
    write_output changed false
    write_output version "${latest}"
    exit 0
fi

if [[ "${current}" != "${latest}" ]]; then
    echo "Checking ${image_repo}:${latest}"
    if ! upstream_image_published "${latest}"; then
        echo "Upstream image ${image_repo}:${latest} is not available yet" >&2
        write_output changed false
        write_output version "${current}"
        exit 0
    fi
    sed -i "s|FROM glitchtip/glitchtip:${current}|FROM glitchtip/glitchtip:${latest}|" Dockerfile
fi

publish_version="$(python3 - "${root}" "${latest}" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
latest = sys.argv[2]

def parse_version(value):
    parts = str(value).split(".")
    if len(parts) != 3 or any(not part.isdigit() for part in parts):
        raise SystemExit(f"Refusing non-semver version: {value}")
    return tuple(int(part) for part in parts)

manifest_path = root / "CloudronManifest.json"
original_manifest = manifest_path.read_text()
manifest = json.loads(original_manifest)
package_version = manifest.get("version")
if not package_version:
    raise SystemExit("CloudronManifest.json has no version")

latest_parts = parse_version(latest)
package_parts = parse_version(package_version)

if latest_parts > package_parts:
    manifest["version"] = latest
    manifest["upstreamVersion"] = latest
    publish = latest
    changelog_path = root / "CHANGELOG"
    body = changelog_path.read_text() if changelog_path.exists() else ""
    header = f"[{latest}]"
    if header not in body:
        if body and not body.endswith("\n"):
            body += "\n"
        updated = f"{header}\n* GlitchTip {latest}\n\n{body}"
        if not updated.endswith("\n"):
            updated += "\n"
        changelog_path.write_text(updated)
elif latest_parts == package_parts:
    manifest["version"] = latest
    manifest["upstreamVersion"] = latest
    publish = latest
else:
    publish = package_version
    print(
        f"GlitchTip {latest} is older than package {package_version}; keeping {package_version}",
        file=sys.stderr,
    )

updated_manifest = json.dumps(manifest, indent=2) + "\n"
if updated_manifest != original_manifest:
    manifest_path.write_text(updated_manifest)

print(publish)
PY
)"

echo "Publishing GlitchTip ${publish_version}"
write_output changed true
write_output version "${publish_version}"
