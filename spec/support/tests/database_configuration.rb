require_relative 'database_configuration_registry'
require 'delegate'

module Tests
  class DatabaseConfiguration < SimpleDelegator
    ENVIRONMENTS = %w(development test production).freeze

    attr_reader :adapter_class

    def self.for(database_name, adapter_name)
      config_class = DatabaseConfigurationRegistry.instance.get(adapter_name)
      config = config_class.new(database_name)
      new(config)
    end

    def initialize(config)
      @adapter_class = config.class.to_s.split('::').last
      super(config)
    end

    def to_hash
      ENVIRONMENTS.each_with_object({}) do |env, config_as_hash|
        config_as_hash[env] = access_configuration(env)
      end
    end

    private

    def access_configuration(env)
      adapter == 'sqlite3' ? sqlite_access_for(env) : postgres_access_for(env)
    end

    def sqlite_access_for(env)
      {
        'adapter' => adapter.to_s,
        'database' => "#{database}_#{env}",
      }
    end

    def postgres_access_for(env)
      sqlite_access_for(env).merge(
        {
          'host' => ENV.fetch('DATABASE_HOST', 'localhost').to_s,
          'port' => ENV.fetch('DATABASE_PORT', '5432').to_s,
          'username' => ENV.fetch('DATABASE_USER', 'postgres').to_s,
          'password' => ENV.fetch('DATABASE_USER_PASSWORD', 'postgres').to_s,
        },
      )
    end
  end
end
