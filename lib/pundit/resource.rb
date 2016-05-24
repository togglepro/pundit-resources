require "active_support/concern"

module Pundit
  module Resource
    extend ActiveSupport::Concern

    included do
      before_save :authorize_create_or_update
      before_remove :authorize_destroy
    end

    module ClassMethods
      def records(options = {})
        context = options[:context]
        Pundit.policy_scope!(context[:current_user], _model_class)
      end
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

    def authorize_destroy
      fail Pundit::NotAuthorizedError, "foo bar baz" unless policy.destroy?
    end

    def records_for(association_name, options={})
      association_reflection = _model.class.reflect_on_association(association_name)

      if association_reflection.macro == :has_many
        records = _model.public_send(association_name)
        policy_scope = Pundit.policy_scope!(
          context[:current_user],
          association_reflection.class_name.constantize
        )
        records.merge(policy_scope)
      elsif [:has_one, :belongs_to].include?(association_reflection.macro)
        record = _model.public_send(association_name)

        if record && Pundit.policy!(context[:current_user], record).show?
          record
        else
          nil
        end
      end
    end
  end
end
