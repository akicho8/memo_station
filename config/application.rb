require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ShogiWeb
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    # https://qiita.com/SoarTec-lab/items/9832bb89402e452b20bb
    config.load_defaults 7.0

    # https://railsguides.jp/configuring.html#config-add-autoload-paths-to-load-path
    # $LOAD_PATHに自動読み込みのパスを追加すべきかどうかを指定します。
    # このフラグはデフォルトでtrueですが、:zeitwerkモードでは早い段階でconfig/application.rbでfalseに設定することをおすすめします。
    config.add_autoload_paths_to_load_path = false # $LOAD_PATH を使わず zeitwerk だけにすると速くなる

    # config.active_support.cache_format_version = 6.1 # Rails 6 に戻す気がなくなったら 7.0 にする

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.time_zone = "Tokyo"
    config.i18n.default_locale = :ja
    config.colorize_logging = false
    config.before_configuration do
      ::AppConfig = {}
      require Rails.root.join("config/app_config")
      config.app_config = AppConfig
    end

    # Psych::DisallowedClass:
    #   Tried to load unspecified class: ActiveSupport::TimeWithZone
    #
    # Psych::DisallowedClass:
    #   Tried to load unspecified class: ActiveSupport::HashWithIndifferentAccess
    # Configuration for the application, engines, and railties goes here.
    #
    # https://stackoverflow.com/questions/74312283/tried-to-load-unspecified-class-activesupporttimewithzone-psychdisallowed
    # config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone, ActiveSupport::Duration]
    #
    # https://zenn.dev/hatsu0412/scraps/4b1db3dd725a86
    config.active_record.use_yaml_unsafe_load = true

    # https://github.com/rails/rails/pull/40370
    config.active_record.legacy_connection_handling = false
  end
end
