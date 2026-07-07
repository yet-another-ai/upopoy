#!/usr/bin/env falcon-host
# frozen_string_literal: true

require "async/service/generic"
require "rbconfig"
require "uri"

class CommandService < Async::Service::Generic
  def setup(container)
    super

    container.spawn(name: name, restart: true, key: name) do |instance|
      instance.exec(*@evaluator.command, chdir: @evaluator.directory)
    end
  end
end

root_path = __dir__
api_url = ENV.fetch("UPOPOY_API_URL", "http://127.0.0.1:3001")
api_uri = URI(api_url)
api_bind = "#{api_uri.scheme}://#{api_uri.host}:#{api_uri.port}"
ruby = RbConfig.ruby
bundle = Gem.bin_path("bundler", "bundle")

service "upopoy-api" do
  service_class CommandService
  directory File.join(root_path, "backend")
  command [
    ruby,
    bundle,
    "exec",
    "falcon",
    "serve",
    "--bind",
    api_bind,
    "--config",
    "config.ru",
    "--threaded",
    "--count",
    ENV.fetch("FALCON_WORKERS", "1")
  ]
end

service "upopoy-frontend" do
  service_class CommandService
  directory File.join(root_path, "frontend")
  command [
    { "VITE_RAILS_PROXY_TARGET" => api_url },
    "pnpm",
    "dev",
    "--host",
    ENV.fetch("VITE_HOST", "0.0.0.0"),
    "--port",
    ENV.fetch("VITE_PORT", "3000")
  ]
end
