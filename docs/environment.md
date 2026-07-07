# Development Environment

This document describes the runtime management conventions for the project development environment.

## Runtime Management

This project uses `mise` to manage language runtimes, package managers, and development tools, including:

- apm
- Ruby
- Node.js
- pnpm

The exact versions are defined by `mise.toml` and `mise.lock` in the repository root. To initialize the development environment, run:

```sh
mise install
```

`mise.lock` is committed to the repository and is used to keep runtime version resolution stricter and more reproducible across machines.

## Running Commands

By default, `mise` expects the environment to be initialized through a login shell. In normal local development, if your shell has already loaded `mise`, you can run project commands directly:

```sh
mise run dev
mise run test
mise run lint
```

If the current environment is not a login shell, which is common for AI agents, automation scripts, and other non-interactive shells, use `mise exec` to explicitly inject the project runtime environment:

```sh
mise exec -- ruby --version
mise exec -- node --version
mise exec -- pnpm --version
mise exec -- apm --version
mise exec -- mise run test
```

When running commands from a non-login shell, prefer:

```sh
mise exec -- <command>
```

This ensures the command uses the apm, Ruby, Node.js, and pnpm versions declared by the project instead of system-global versions.

## Dependency Versions

As a general rule, this project uses the latest stable versions of dependencies. When adding or upgrading dependencies, prefer stable releases and avoid prerelease, nightly, canary, or unpublished versions unless a specific task requires them and the decision has been discussed.

If you change any content in `mise.toml`, or if a runtime needs to move to a newer patch version, run:

```sh
mise lock
```

Commit the resulting `mise.lock` update together with the `mise.toml` change so the runtime version policy stays explicit.
