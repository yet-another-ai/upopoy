# frozen_string_literal: true

require "fileutils"
require "pathname"
require "rbconfig"
require "tmpdir"

namespace :openapi do
  desc "Verify generated OpenAPI documentation matches the committed file"
  task :check do
    expected = Rails.root.join("openapi/v1/openapi.yaml")

    abort "Missing committed OpenAPI spec at #{expected}" unless expected.file?

    FileUtils.mkdir_p(Rails.root.join("tmp"))

    Dir.mktmpdir("openapi-check-", Rails.root.join("tmp").to_s) do |tmp_dir|
      generated = Pathname.new(tmp_dir).join("v1/openapi.yaml")
      env = {
        "OPENAPI_ROOT" => tmp_dir,
        "RAILS_ENV" => "test"
      }

      unless system(env, RbConfig.ruby, "bin/rails", "rswag")
        abort "Failed to regenerate OpenAPI documentation."
      end

      abort "OpenAPI generation did not write #{generated}" unless generated.file?

      if FileUtils.compare_file(expected, generated)
        puts "OpenAPI spec is up to date."
        next
      end

      abort <<~MESSAGE
        OpenAPI spec is out of date.

        Run:
          RAILS_ENV=test ruby bin/rails rswag

        Then commit:
          #{expected.relative_path_from(Rails.root)}

        To inspect the difference:
          diff -u #{expected} #{generated}
      MESSAGE
    end
  end
end
