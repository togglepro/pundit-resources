module V1
  class BaseResource < JSONAPI::Resource
    abstract

    attribute :created_at

    attribute :updated_at

    before_save :authorize_create_or_update

    class << self
      def creatable_fields(context)
        super - [:id, :created_at, :updated_at]
      end

      alias_method :updatable_fields, :creatable_fields

      def records(options = {})
        context = options[:context]
        Pundit.policy_scope!(context[:current_user], _model_class)
      end
    end

    def fetchable_fields
      super
    end

    def current_user
      context&.[](:current_user)
    end

    def policy
      Pundit.policy!(current_user, _model)
    end

    def authorize_create_or_update
      permission = _model.new_record? ? :create? : :update?
      raise Pundit::NotAuthorizedError unless policy.public_send(permission)
    end
  end
end
