# GlitchTip for Cloudron

GlitchTip collects application errors, uptime checks, and logs. This unofficial package uses PostgreSQL, Redis, outbound mail, and TLS from Cloudron.

Install it from the Cloudron dashboard. Open App Store, choose Add custom app, then Community app, and paste this address:

```text
https://raw.githubusercontent.com/paramedicspecialist/glitchtip-cloudron/main/CloudronVersions.json
```

With Cloudron sign-in, the first Cloudron account becomes the administrator. Create an organization in the app. Without Cloudron sign-in, create the first account on the sign-in page. That person creates the organization, and public signup closes after that account.

Uploads, including sourcemaps, are stored in `/app/data/media`.

Optional settings live in `/app/data/env.sh`. The file is created on first start and lists the settings you can change. The full GlitchTip list is https://glitchtip.com/documentation/install/#configuration. Restart the app after editing it. Set `ENABLE_SOCIAL_APPS_USER_REGISTRATION=false` to close Cloudron sign-up after the first account.

The package version is the GlitchTip version. A daily Action publishes a new catalog entry when GlitchTip publishes a stable release and the matching Docker Hub image exists. Cloudron updates from `CloudronVersions.json`. Older catalog entries stay, so an install can roll back. A future major release can require a newer PostgreSQL than Cloudron's addon. If migrations fail after that upgrade, install the previous catalog version.

Raise the app memory limit for a busy instance. The default is 1 GiB.

## Licence

GlitchTip is copyright 2019 GlitchTip and is licensed under the MIT License: https://gitlab.com/glitchtip/glitchtip-backend/-/blob/master/LICENSE

This repository is an unofficial Cloudron package. It is not published by the GlitchTip project. The startup scripts in this repository are separate from GlitchTip and are also MIT. The image is built from the official `glitchtip/glitchtip` image. The icon is the GlitchTip mark.
