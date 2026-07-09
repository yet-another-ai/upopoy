# Deployment Overview

upopoy production deployment has two concerns:

- Deploy the application stack: Rails API, built Vue frontend assets, PostgreSQL, and the reverse proxy rules that keep the app same-origin.
- Deploy the documentation site: a static VitePress build from `docs/.vitepress/dist`.

## Application Routing

Development and production should keep the same URL shape:

- `/` and frontend asset paths are served by the Vue/Vite app.
- `/api` is proxied to Rails.
- `/pghero` is proxied to Rails.
- `/rails-assets` is proxied to Rails for mounted engine assets.

For production nginx, serve the built frontend as the default app and proxy the Rails-owned paths above to the Rails/Falcon upstream.

## Build Inputs

Application image builds are checked in CI through the existing Docker workflow. Documentation builds are checked with:

```sh
pnpm --filter docs build
```

The VitePress output directory is:

```text
docs/.vitepress/dist
```

## Authentication

Email/password login is available by default. SSO login is configured through OmniAuth providers in the Rails backend and exposed to the frontend through `/api/v1/auth/providers`.

See [SSO Login](./sso.md) for provider setup, callback URLs, required environment variables, and rollout checks.

## File Storage

Drive file uploads and file versions use Rails ActiveStorage. Production currently defaults to local disk storage backed by the Kamal `backend_storage` volume.

See [ActiveStorage](./active-storage.md) for local volume setup, S3-compatible storage configuration, backup guidance, and verification checks.
