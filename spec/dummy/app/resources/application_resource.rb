class ApplicationResource < JSONAPI::Resource
  include Pundit::Resource

  abstract
end
