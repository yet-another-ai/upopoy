# Usage Overview

upopoy is an AI-collaborative SaaS MVP with a Rails backend and a Vue/Vite frontend. The first implementation focuses on project and Kanban task management.

## Project Shape

- `backend/` contains the Rails API, PostgreSQL-backed domain model, tests, and OpenAPI checks.
- `frontend/` contains the Vue 3 application, Vite configuration, Vitest unit tests, and Playwright end-to-end tests.
- `docs/` contains this VitePress documentation site.

## Common Commands

Install the project runtime and dependencies:

```sh
mise install
mise exec -- bundle install --gemfile backend/Gemfile
pnpm install
```

Run the main development environment:

```sh
mise run dev
```

Run the documentation site:

```sh
pnpm docs:dev
```

Build the documentation site:

```sh
pnpm docs:build
```

## Quality Checks

Use the repository-level tasks for the application:

```sh
mise run test
mise run lint
mise run format
```

Use the docs package scripts for documentation:

```sh
pnpm --filter docs build
pnpm --filter docs preview
```
