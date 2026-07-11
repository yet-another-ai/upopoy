# SSO Login

upopoy supports SSO through Devise + OmniAuth. Production starts with no OAuth providers enabled, so each deployment must explicitly configure the providers it wants to expose.

## How It Works

1. The frontend calls `/api/v1/auth/providers`.
2. The backend returns enabled providers from `backend/config/auth_providers.yml`.
3. The login page links users to `/api/v1/auth/:provider`.
4. OmniAuth completes the provider callback at `/api/v1/auth/:provider/callback`.
5. The backend creates or finds the user, issues a JWT, and redirects to `FRONTEND_AUTH_CALLBACK_URL`.

The frontend callback route is:

```text
/auth/callback
```

## Configure A Provider

Add the provider strategy gem if the provider is not already available. For example, GitHub OAuth typically needs an OmniAuth GitHub strategy gem in `backend/Gemfile`.

Configure production providers in `backend/config/auth_providers.yml`:

```yaml
production:
  <<: *default
  providers:
    - name: github
      label: GitHub
      enabled: true
      args:
        - <%= ENV.fetch("GITHUB_CLIENT_ID") %>
        - <%= ENV.fetch("GITHUB_CLIENT_SECRET") %>
      options:
        scope: "user:email"
```

Provider `name` must match the OmniAuth strategy name. The frontend displays `label` on the login button.

## Environment Variables

Set these values in the Rails runtime:

```sh
FRONTEND_AUTH_CALLBACK_URL=https://app.example.com/auth/callback
GITHUB_CLIENT_ID=...
GITHUB_CLIENT_SECRET=...
```

`FRONTEND_AUTH_CALLBACK_URL` must point to the public frontend callback URL. For same-origin production deployments, use the app origin plus `/auth/callback`.

## Identity Provider Settings

In the identity provider dashboard, register the Rails callback URL:

```text
https://app.example.com/api/v1/auth/github/callback
```

Use the same public origin that users use to access the app. If the app is behind a reverse proxy, make sure HTTPS, host, and forwarded headers are preserved so generated OAuth URLs match the public URL.

## Login Policy

System admins can control built-in authentication from the admin settings page:

- Disable registration when accounts should only be created through an invite or first SSO login.
- Disable email login when SSO should be the only user-facing login method.

Do not disable email login until at least one system admin can successfully sign in through SSO.

## User Provisioning

On a successful SSO callback, the backend:

- Finds an existing OAuth identity by provider and UID.
- Otherwise finds or creates a user by the email returned by the provider.
- Links the OAuth identity to that user.
- Generates a random password for newly created SSO users.

If the provider does not return an email address, upopoy creates a fallback local email in the form:

```text
provider-uid@oauth.upopoy.local
```

Prefer provider scopes that return a verified email address.

## Rollout Checklist

- The OmniAuth strategy gem is installed in the backend image.
- `backend/config/auth_providers.yml` has the production provider entry.
- Provider client ID and secret are available in the Rails environment.
- `FRONTEND_AUTH_CALLBACK_URL` points to the public frontend `/auth/callback` route.
- The provider dashboard allows `https://app.example.com/api/v1/auth/:provider/callback`.
- `/api/v1/auth/providers` returns the provider in production.
- A test user can complete SSO and reach the app.
- Email login is disabled only after SSO admin access is confirmed.
