class UsersController < JSONAPI::ResourceController
  include Pundit::ResourceController

  def current_user
  end
end
