class UserResource < JSONAPI::Resource
  include Pundit::Resource

  attribute :created_at

  # include relationship with and without relation_name:
  # to check both cases are handled
  has_one :x_post, class_name: "Post"
  has_one :post, relation_name: :x_post, class_name: "Post"
end
