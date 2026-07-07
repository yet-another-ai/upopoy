auth_provider_config = Rails.application.config_for(:auth_providers)

enabled_auth_providers = Array(auth_provider_config.fetch(:providers, [])).filter_map do |provider|
  provider = provider.deep_symbolize_keys
  next if provider[:enabled] == false

  {
    name: provider.fetch(:name).to_s,
    label: provider[:label].presence || provider.fetch(:name).to_s.titleize,
    args: Array(provider[:args]),
    options: provider.fetch(:options, {}).deep_symbolize_keys
  }
end

Rails.application.config.x.auth_frontend_callback_url =
  auth_provider_config.fetch(:frontend_callback_url)
Rails.application.config.x.auth_providers = enabled_auth_providers
Rails.application.config.x.auth_provider_names =
  enabled_auth_providers.map { |provider| provider.fetch(:name).to_sym }

OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
