module Pundit
  module ResourceController
    extend ActiveSupport::Concern

    included do
      include ActionController::Rescue

      JSONAPI.configure do |config|
        config.exception_class_whitelist = [Pundit::NotAuthorizedError]
      end

      rescue_from Pundit::NotAuthorizedError, with: :reject_forbidden_request
    end

    protected

    def reject_forbidden_request(error)
      type = error.record.class.name.underscore.humanize(capitalize: false)
      error = JSONAPI::Error.new(
        code: JSONAPI::FORBIDDEN,
        status: :forbidden,
        title: "#{params[:action].capitalize} Forbidden",
        detail: "You don't have permission to #{params[:action]} this #{type}.",
      )

      render json: { errors: [error] }, status: 403
    end

    def context
      { current_user: current_user }
    end

    def current_user
    end
  end
end
