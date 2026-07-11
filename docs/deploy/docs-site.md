# Documentation Site Deployment

The documentation site is a VitePress project in the `docs` workspace package.

## Build

```sh
pnpm install --frozen-lockfile
pnpm docs:build
```

The static output is written to:

```text
docs/.vitepress/dist
```

## Preview

```sh
pnpm docs:preview
```

## Hosting Settings

For static hosting providers, use:

| Setting | Value |
| --- | --- |
| Build command | `pnpm docs:build` |
| Output directory | `docs/.vitepress/dist` |
| Node version | `24` |
| Package manager | `pnpm` |

If the site is deployed under a subpath, set `base` in `docs/.vitepress/config.ts` to that path. For example, GitHub Pages for a repository site usually needs:

```ts
export default defineConfig({
  base: '/upopoy/'
})
```

## CI Check

The GitHub Actions frontend job installs workspace dependencies and builds the docs package after frontend tests:

```sh
pnpm --filter docs build
```
