class PostPolicy < ApplicationPolicy
  def update?
    false
  end

  class Scope < Scope
  end
end
