module LocalizesRequest
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private

  def switch_locale(&action)
    I18n.with_locale(locale_from_accept_language, &action)
  end

  def locale_from_accept_language
    header = request.headers["Accept-Language"].to_s
    locales = header.split(",").filter_map do |entry|
      locale, quality = entry.strip.split(";q=", 2)
      normalized_locale = normalize_locale(locale)
      next unless normalized_locale

      [ normalized_locale, quality ? quality.to_f : 1.0 ]
    end

    locales.max_by { |_locale, quality| quality }&.first || I18n.default_locale
  end

  def normalize_locale(locale)
    normalized = locale.to_s.strip.tr("_", "-").downcase
    return nil if normalized.blank?
    return :"zh-CN" if [ "zh", "zh-cn", "zh-hans" ].include?(normalized)
    return :"zh-CN" if normalized.start_with?("zh-cn-", "zh-hans-")
    return :en if normalized == "en" || normalized.start_with?("en-")

    nil
  end
end
