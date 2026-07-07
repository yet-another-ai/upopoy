# upopoy

upopoy is an AI-collaborative SaaS MVP. The first implementation focuses on project and Kanban task management with Rails API-only backend and Vue/Vite frontend.

## Stack

- Runtime management: `mise` with Ruby `4.0.5` and Node `24`
- Backend: Rails API-only, PostgreSQL, RSpec, FactoryBot, RuboCop
- Frontend: Vue 3, Vite, TypeScript, shadcn-vue, Vitest, Playwright, ESLint, Prettier

## Setup

```sh
mise install
mise exec -- bundle install --gemfile backend/Gemfile
cd frontend && pnpm install
```

## Development

```sh
mise run dev
```

Rails runs on `http://localhost:3001`; Vite runs on `http://localhost:3000` and proxies `/api` to Rails.

## Quality

```sh
mise run test
mise run lint
mise run format
```

Focused commands are also available:

```sh
mise run backend-test
mise run backend-lint
mise run frontend-test
mise run frontend-lint
```
