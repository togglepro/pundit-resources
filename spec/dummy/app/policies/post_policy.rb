class PostPolicy < ApplicationPolicy
  def update?
    false
  end

  def destroy?
    false
  end

  class Scope < Scope
  end
end
