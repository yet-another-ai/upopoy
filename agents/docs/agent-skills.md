# Agent Skills

This project uses APM to manage project-level agent skills. The manifest is
`apm.yml`, the lockfile is `apm.lock.yaml`, and installed skills are deployed to
`.agents/skills/`.

## Installed Skills

The current third-party skills come from `anthropics/skills`:

- `frontend-design`: UI design guidance for building more intentional, less
  generic frontend experiences. This is useful for the Vue, Vite, and
  shadcn-vue frontend.
- `webapp-testing`: Playwright-based workflows for testing local web
  applications, capturing screenshots, and debugging browser behavior.
- `skill-creator`: Guidance and tooling for creating, improving, and evaluating
  additional agent skills as the project grows.

The dependencies in `apm.yml` are intentionally not pinned to commit SHAs. APM
records resolved versions and content hashes in `apm.lock.yaml`.

## Common Commands

Install the skills declared in `apm.yml`:

```sh
mise exec -- apm install
```

Update skill dependencies and refresh the lockfile:

```sh
mise exec -- apm update
```

Audit installed skill files:

```sh
mise exec -- apm audit
```

When running from a non-login shell, keep using `mise exec --` so APM runs from
the project-managed environment.
