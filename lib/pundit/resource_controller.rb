module Pundit
  module ResourceController
    extend ActiveSupport::Concern

    included do
      include ActionController::Rescue
      include AbstractController::Callbacks

      after_action :enforce_policy_use

      JSONAPI.configure do |config|
        error = Pundit::NotAuthorizedError
        unless config.exception_class_allowlist.include? error
          config.exception_class_allowlist << error
          config.use_relationship_reflection = true
        end
      end

      rescue_from Pundit::NotAuthorizedError, with: :reject_forbidden_request
    end

    protected

    def enforce_policy_use
      return if @policy_used || response.status.in?(400...600)
      raise Pundit::AuthorizationNotPerformedError,
        "#{params[:controller]}##{params[:action]}"
    end

    def reject_forbidden_request(error)
      type = error.record.class.name.underscore.humanize(capitalize: false)
      human_action = params[:action].humanize(capitalize: false)
      error = JSONAPI::Error.new(
        code: JSONAPI::FORBIDDEN,
        status: :forbidden,
        title: "#{human_action.titleize} Forbidden",
        detail: "You don't have permission to #{human_action} this #{type}.",
      )

      render json: { errors: [error] }, status: 403
    end

    def context
      { current_user: current_user, policy_used: -> { @policy_used = true } }
    end
  end
end
