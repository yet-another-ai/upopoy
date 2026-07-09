# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

## API docs

OpenAPI documentation is generated from rswag request specs:

```sh
RAILS_ENV=test mise exec -- ruby bin/rails rswag
```

The generated spec is written to `openapi/v1/openapi.yaml` and served through
Swagger UI at `/api-docs`.

To verify the committed spec is up to date without rewriting it:

```sh
RAILS_ENV=test mise exec -- bundle exec rake openapi:check
```

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
