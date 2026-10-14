"""Cloudron behavior loaded from a .pth file when Python starts."""

from __future__ import annotations

import os

_connected = False


def _install() -> None:
    from django.apps.registry import Apps

    if getattr(Apps.populate, "_cloudron_wrapped", False):
        return

    original = Apps.populate

    def populate(self, installed_apps=None):
        original(self, installed_apps)
        _after_populate()

    populate._cloudron_wrapped = True
    Apps.populate = populate


def _after_populate() -> None:
    global _connected
    if _connected:
        return
    _connected = True

    from django.conf import settings

    if os.environ.get("CLOUDRON_APP_DOMAIN"):
        settings.SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

    from allauth.account.signals import user_signed_up

    user_signed_up.connect(
        _promote_first_social_admin,
        dispatch_uid="cloudron_first_social_admin",
    )


async def _promote_first_social_admin(sender, request, user, sociallogin=None, **kwargs):
    if sociallogin is None:
        return

    from asgiref.sync import sync_to_async

    promoted = await sync_to_async(_mark_first_admin, thread_sensitive=True)(user.pk)
    if promoted:
        user.is_superuser = True
        user.is_staff = True


def _mark_first_admin(user_id: int) -> bool:
    from django.contrib.auth import get_user_model
    from django.db import connection, transaction

    User = get_user_model()
    with transaction.atomic():
        with connection.cursor() as cursor:
            cursor.execute("SELECT pg_advisory_xact_lock(%s)", [872341])
        if User.objects.filter(is_superuser=True).exists():
            return False
        User.objects.filter(pk=user_id).update(is_superuser=True, is_staff=True)
    return True


_install()
