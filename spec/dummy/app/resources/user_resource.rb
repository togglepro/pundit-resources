class UserResource < JSONAPI::Resource
  include Pundit::Resource

  attribute :created_at
end
