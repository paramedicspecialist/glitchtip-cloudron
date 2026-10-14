#!/usr/bin/env python3
"""Migrate GlitchTip and record the Cloudron OpenID app."""

from __future__ import annotations

import os
import subprocess
import sys


PROVIDER = "openid_connect"
PROVIDER_ID = "cloudron"


def main() -> None:
    os.chdir("/code")
    _run(["migrate", "--no-input", "--skip-checks"])
    _run(["maintain_partitions"])
    _run(["createcachetable"], ignore_exists=True)
    _configure_site_and_oidc()


def _run(args: list[str], ignore_exists: bool = False) -> None:
    result = subprocess.run(
        [sys.executable, "manage.py", *args],
        cwd="/code",
        text=True,
        capture_output=True,
    )
    if result.stdout:
        print(result.stdout, end="" if result.stdout.endswith("\n") else "\n")
    if result.stderr:
        print(result.stderr, file=sys.stderr, end="" if result.stderr.endswith("\n") else "\n")
    if result.returncode == 0:
        return
    combined = f"{result.stdout}\n{result.stderr}"
    if ignore_exists and "already exists" in combined.lower():
        return
    raise SystemExit(result.returncode)


def _configure_site_and_oidc() -> None:
    domain = os.environ.get("CLOUDRON_APP_DOMAIN", "").strip()
    if not domain:
        return

    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "glitchtip.settings")
    if "/code" not in sys.path:
        sys.path.insert(0, "/code")

    import django

    django.setup()

    from allauth.socialaccount.models import SocialApp

    client_id = os.environ.get("CLOUDRON_OIDC_CLIENT_ID", "").strip()
    secret = os.environ.get("CLOUDRON_OIDC_CLIENT_SECRET", "").strip()
    discovery = os.environ.get("CLOUDRON_OIDC_DISCOVERY_URL", "").strip()
    provider_name = os.environ.get("CLOUDRON_OIDC_PROVIDER_NAME", "").strip() or "Cloudron"

    existing = list(
        SocialApp.objects.filter(provider=PROVIDER, provider_id=PROVIDER_ID).order_by("id")
    )
    if not (client_id and secret and discovery):
        if existing:
            SocialApp.objects.filter(pk__in=[app.pk for app in existing]).delete()
        print("startup oidc=off")
        return

    app = existing[0] if existing else SocialApp(provider=PROVIDER, provider_id=PROVIDER_ID)
    app.name = provider_name[:40]
    app.client_id = client_id
    app.secret = secret
    app.settings = {"server_url": discovery}
    app.save()
    extras = [row.pk for row in existing[1:]]
    if extras:
        SocialApp.objects.filter(pk__in=extras).delete()
    print(f"startup oidc=on site={domain}")


if __name__ == "__main__":
    main()
