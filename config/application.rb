require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative 'initializers/i18n'

module Comakery
  class Application < Rails::Application
    config.load_defaults '5.1'
    config.active_record.belongs_to_required_by_default = false  # see https://blog.bigbinary.com/2016/02/15/rails-5-makes-belong-to-association-required-by-default.html

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.default_locale = :app
    config.i18n.fallbacks = [:en]

    config.allow_signup = true
    config.project_slug = Dir.pwd.split(File::SEPARATOR).last.underscore
    # appears in main layout meta tag

    # lib/ is for code that is entirely independent of your Rails app
    # app/lib/ is for code that expects Rails (esp. models) but which is not itself a model
    config.autoload_paths << Rails.root.join("app", "lib")
    config.autoload_paths << Rails.root.join("app", "interactors")
    config.autoload_paths << Rails.root.join("app", "queries")

    routes.default_url_options[:host] = ENV['APP_HOST'].presence || "localhost:#{ENV['PORT'].presence || 3000}"
    routes.default_url_options[:protocol] = ENV['APP_PROTOCOL'].presence || 'https://'

    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    cdn_host = ENV['EDGE_URL']
    if cdn_host.present?
      config.action_controller.asset_host = cdn_host
      config.font_assets.origin = "*"
    end

    config.allow_missing_ethereum_bridge = false

    config.generators do |g|
      g.test_framework :rspec
    end

    class CustomCamelize
      def self.camelize(string)
        string.sub(/^_/, '').underscore.camelize(:lower)
      end
    end

    config.react.camelize_props = true
    config.middleware.use OliveBranch::Middleware, inflection: 'camel', camelize: CustomCamelize.method(:camelize)

    config.middleware.use HTMLProofer::Middleware if Rails.env.development? || Rails.env.test?
    # Use Redis for Cache Store
    redis_provider = ENV.fetch("REDIS_PROVIDER") { "REDIS_URL" }
    redis_url = ENV.fetch(redis_provider) { "redis://localhost:6379/1" }

    config.custom_redis_params = {}

    # Disable SSL for Redis in Heroku env:
    # https://help.heroku.com/HC0F8CUS/redis-connection-issues
    if ENV["REDIS_SSL_NONE"]
      config.custom_redis_params = {
        ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
      }
    end

    config.cache_store = :redis_cache_store, { url: redis_url, expires_in: 1.hour }.merge(config.custom_redis_params)
    config.action_controller.perform_caching = true

    # Output logs only to STDOUT
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end
end
