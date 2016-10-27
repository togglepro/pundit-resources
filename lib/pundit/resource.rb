require "active_support/concern"

module Pundit
  module Resource
    extend ActiveSupport::Concern

    included do
      define_jsonapi_resources_callbacks :policy_authorize

      before_save :authorize_create_or_update
      before_remove :authorize_destroy
    end

    module ClassMethods
      def records(options = {})
        warn_if_show_defined

        context = options[:context]
        context[:policy_used].try(:call)
        Pundit.policy_scope!(context[:current_user], _model_class)
      end

      private

      def warn_if_show_defined
        policy_class = Pundit::PolicyFinder.new(_model_class.new).policy!
        if policy_class.instance_methods(false).include?(:show?)
          puts "WARN: pundit-resources does not use the show? action."
          puts "      #{policy_class::Scope} will be used instead."
        end
      end
    end

    protected

    def can(method)
      run_callbacks :policy_authorize do
        context[:policy_used].try(:call)
        policy.public_send(method)
      end
    end

    def current_user
      return unless context

      context[:current_user]
    end

    def policy
      Pundit.policy!(current_user, _model)
    end

    def authorize_create_or_update
      action = _model.new_record? ? :create : :update
      not_authorized!(action) unless can :"#{action}?"
    end

    def authorize_destroy
      not_authorized! :destroy unless can :destroy?
    end

    def records_for(association_name, options={})
      relationships = self.class._relationships.
        values.
        select { |r| r.relation_name(context: @context) == association_name }.
        uniq(&:class)

      unless relationships.count == 1
        raise "Can't infer relationship type for #{association_name}"
      end

      relationship = relationships.first

      case relationship
      when JSONAPI::Relationship::ToMany
        records = _model.public_send(association_name)
        policy_scope = Pundit.policy_scope!(
          context[:current_user],
          records
        )
        records.merge(policy_scope)
      when JSONAPI::Relationship::ToOne
        record = _model.public_send(association_name)

        # Don't rely on policy.show? being defined since it isn't used for
        # show actions directly and should always have the same behaviour.
        if record && show?(Pundit.policy!(context[:current_user], record), record.id)
          record
        else
          nil
        end
      end
    end

    private

    def not_authorized!(action)
      options = { query: action, record: _model, policy: policy }
      raise Pundit::NotAuthorizedError, options
    end

    def show?(policy, record_id)
      policy.scope.where(id: record_id).exists?
    end
  end
end
