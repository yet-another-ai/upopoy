#!/usr/bin/env falcon-host
# frozen_string_literal: true

require 'async/service/generic'
require 'rbconfig'
require 'uri'

# Runs an external command as an async-service managed process.
class CommandService < Async::Service::Generic
  def setup(container)
    super

    container.spawn(name: name, restart: true, key: name) do |instance|
      instance.exec(*@evaluator.command, chdir: @evaluator.directory)
    end
  end
end

root_path = __dir__
container = ENV['UPOPOY_CONTAINER'] == 'true'
backend_path = container ? root_path : File.join(root_path, 'backend')
api_url = container ? 'http://127.0.0.1:9292' : ENV.fetch('UPOPOY_API_URL', 'http://127.0.0.1:3001')
api_uri = URI(api_url)
api_bind = "#{api_uri.scheme}://#{api_uri.host}:#{api_uri.port}"
ruby = RbConfig.ruby
bundle = Gem.bin_path('bundler', 'bundle')

service 'upopoy-api' do
  service_class CommandService
  directory backend_path
  command [
    ruby,
    bundle,
    'exec',
    'falcon',
    'serve',
    '--bind',
    api_bind,
    '--config',
    'config.ru',
    '--threaded',
    '--count',
    ENV.fetch('FALCON_WORKERS', '1')
  ]
end

if container
  service 'upopoy-nginx' do
    service_class CommandService
    directory root_path
    command [
      'nginx',
      '-g',
      'daemon off;'
    ]
  end
else
  service 'upopoy-frontend' do
    service_class CommandService
    directory File.join(root_path, 'frontend')
    command [
      { 'VITE_RAILS_PROXY_TARGET' => api_url },
      'pnpm',
      'dev',
      '--host',
      ENV.fetch('VITE_HOST', '0.0.0.0'),
      '--port',
      ENV.fetch('VITE_PORT', '3000')
    ]
  end
end
