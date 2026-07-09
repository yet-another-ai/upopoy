# syntax=docker/dockerfile:1
# check=error=true

ARG NODE_VERSION=24
ARG PNPM_VERSION=11.7.0
ARG RUBY_VERSION=4.0.5

FROM docker.io/library/node:${NODE_VERSION}-bookworm-slim AS frontend-build

WORKDIR /app

ENV PNPM_HOME="/pnpm" \
    PATH="/pnpm:$PATH"

RUN corepack enable && corepack prepare "pnpm@${PNPM_VERSION}" --activate

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY frontend/package.json frontend/package.json
RUN pnpm install --frozen-lockfile --filter frontend

COPY frontend/ frontend/
RUN pnpm --filter frontend build

FROM docker.io/library/ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD="/usr/local/lib/libjemalloc.so" \
    RACK_ENV="production" \
    RAILS_ENV="production" \
    RAILS_LOG_TO_STDOUT="1" \
    UPOPOY_CONTAINER="true"

FROM base AS backend-build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libvips libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile -j 1 --gemfile

COPY backend/ ./
COPY --from=frontend-build /app/frontend/dist/ ./public/

RUN bundle exec bootsnap precompile -j 1 app/ lib/
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

FROM base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y nginx && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash

COPY --chown=rails:rails --from=backend-build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --chown=rails:rails --from=backend-build /rails /rails
COPY --chown=rails:rails falcon.rb /rails/falcon.rb
COPY docker/nginx.conf /etc/nginx/nginx.conf

USER 1000:1000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bundle", "exec", "falcon", "host", "/rails/falcon.rb"]
