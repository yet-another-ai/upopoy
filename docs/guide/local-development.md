# Local Development

This project uses `mise` to manage Ruby, Node.js, pnpm, and supporting tools. The versions are declared in `mise.toml` and locked in `mise.lock`.

## Setup

```sh
mise install
mise exec -- bundle install --gemfile backend/Gemfile
pnpm install
```

When a command is run from automation or a non-login shell, prefer `mise exec --` so the project-managed runtime is used instead of a system-global tool.

## Application Servers

Start the Rails backend and Vue frontend together:

```sh
mise run dev
```

Falcon starts:

- Rails backend at `http://localhost:3001`
- Vite frontend at `http://localhost:3000`

Run only the Rails API:

```sh
mise run backend
```

Run only the Vue frontend:

```sh
mise run frontend
```

Run only the documentation site:

```sh
mise run docs
```

## Workspace Commands

The frontend and docs are pnpm workspace packages. From the repository root, run package scripts with filters:

```sh
pnpm --filter frontend build
pnpm --filter docs build
```

Root aliases are also available:

```sh
pnpm frontend:build
pnpm docs:build
```
