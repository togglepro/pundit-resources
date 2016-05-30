require_relative 'boot'

require 'rails/all'

Bundler.require(*Rails.groups)
require "pundit/resources"

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    if ActiveRecord::Base.respond_to?(:belongs_to_required_by_default=)
      config.active_record.belongs_to_required_by_default = false
    end
  end
end

