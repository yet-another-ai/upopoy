assets_precompile = defined?(Rake) &&
  Rake.respond_to?(:application) &&
  Rake.application.top_level_tasks.any? { |task| task.to_s.start_with?("assets:") }

if Rails.env.production? && !assets_precompile
  missing_pghero_auth = %w[PGHERO_USERNAME PGHERO_PASSWORD].select do |key|
    ENV.fetch(key, "").blank?
  end

  if missing_pghero_auth.any?
    raise "Missing #{missing_pghero_auth.join(', ')} for PgHero basic authentication"
  end
end
