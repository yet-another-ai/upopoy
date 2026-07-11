# upopoy

upopoy is an AI-collaborative SaaS MVP. The first implementation focuses on project and Kanban task management with a Rails backend and Vue/Vite frontend.

## Stack

- Runtime management: `mise` with Ruby `4.0.5` and Node `24`
- Backend: Rails, Falcon, PostgreSQL, RSpec, FactoryBot, RuboCop
- Frontend: Vue 3, Vite, TypeScript, shadcn-vue, Vitest, Playwright, ESLint, Prettier

## Setup

```sh
mise install
mise exec -- bundle install --gemfile backend/Gemfile
pnpm install
```

## Development

```sh
mise run dev
```

Falcon reads `falcon.rb` and starts both services:

- Rails backend on `http://localhost:3001`
- Vite frontend on `http://localhost:3000`, proxying `/api`, `/pghero`, and `/rails-assets` to Rails

You can still run only the Rails API with:

```sh
mise run backend
```

## Routing

Development and production both use a same-origin shape:

- `/` and frontend asset paths are served by the Vue/Vite app
- `/api` is proxied to Rails
- `/pghero` is proxied to Rails
- `/rails-assets` is proxied to Rails for mounted engine assets like PgHero CSS and JavaScript

For production nginx, serve the built frontend as the default app and proxy the Rails-owned paths above to the Rails/Falcon upstream.

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

The frontend is a pnpm workspace package. From the repository root, use
`pnpm --filter frontend <script>` or the root aliases such as
`pnpm frontend:build`.

Agent-facing development notes live in [AGENT.md](AGENT.md). The `docs/`
directory is reserved for VitePress deployment and usage documentation.
