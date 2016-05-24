module Pundit
  module ResourceController
    protected

    def context
      { current_user: current_user }
    end
  end
end
