# Agent Guide

This file is the entry point for AI agents and automation working in this
repository. Keep product deployment and user-facing documentation in `docs/`;
keep agent-facing development conventions here and under `agents/docs/`.

## Project Shape

- Product: AI-collaborative SaaS MVP for project and Kanban task management.
- Backend: Rails, Falcon, PostgreSQL, RSpec, FactoryBot, RuboCop.
- Frontend: Vue 3, Vite, TypeScript, shadcn-vue, Vitest, Playwright, ESLint,
  Prettier.
- Runtime management: `mise` with locked versions in `mise.toml` and
  `mise.lock`.

## Common Commands

Use the project-managed toolchain:

```sh
mise install
mise run dev
mise run test
mise run lint
mise run format
```

When running from a non-login shell, use `mise exec --` so commands resolve the
repository-managed Ruby, Node.js, pnpm, and apm versions:

```sh
mise exec -- mise run test
mise exec -- ruby --version
mise exec -- pnpm --version
```

## Supporting Notes

- [Development environment](agents/docs/environment.md)
- [Agent skills](agents/docs/agent-skills.md)
- [Permission model](agents/docs/permission-model.md)

## Documentation Boundary

The `docs/` directory is reserved for the VitePress documentation site, focused
on deployment and usage documentation. Do not place internal agent notes,
implementation checklists, or development-only architecture notes there.
