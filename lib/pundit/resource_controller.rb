module Pundit
  module ResourceController
    extend ActiveSupport::Concern

    included do
      include ActionController::Rescue
      include AbstractController::Callbacks

      after_action :enforce_policy_use

      JSONAPI.configure do |config|
        error = Pundit::NotAuthorizedError
        unless config.exception_class_whitelist.include? error
          config.exception_class_whitelist << error
        end
      end

      rescue_from Pundit::NotAuthorizedError, with: :reject_forbidden_request
    end

    protected

    def enforce_policy_use
      return if @policy_used
      raise Pundit::AuthorizationNotPerformedError,
        "#{params[:controller]}##{params[:action]}"
    end

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
      { current_user: current_user, policy_used: -> { @policy_used = true } }
    end

    def current_user
      raise NotImplementedError, "#{self.class} does not override #current_user"
    end
  end
end
