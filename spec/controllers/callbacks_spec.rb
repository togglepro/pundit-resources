require "rails_helper"

RSpec.describe UsersController, type: :controller do
  def do_request
    delete :destroy, params_hash(id: User.create!.id)
  end

  def self.set_callback(klass, name, time, method)
    before do
      klass.set_callback(name, time, method)
      unless klass.method_defined?(method)
        allow_any_instance_of(klass).to receive(method)
      end
    end
    after { klass.skip_callback(name, time, method) }
  end

  def self.let_temporary_exception_class(name)
    let(name) { Class.new(StandardError) }
    before { JSONAPI.configuration.exception_class_whitelist.push error }
    after { JSONAPI.configuration.exception_class_whitelist.pop }
  end

  context "before authorizing" do
    let_temporary_exception_class :error
    set_callback UserResource, :policy_authorize, :before, :test

    before do
      # Raise an exception when the policy is used.
      # This means that the after actions won't be called.
      allow_any_instance_of(UserPolicy).to receive(:destroy?) { raise error }
    end

    it "calls before_policy_authorize callbacks" do
      expect_any_instance_of(UserResource).to receive(:test)
      expect { do_request }.to raise_error error
    end
  end

  context "after authorizing" do
    set_callback UserResource, :policy_authorize, :after, :test

    before do
      # Set an instance variable when the policy is used so it can be tested
      # that after actions are run after and not before.
      original = UserPolicy.instance_method(:destroy?)
      allow_any_instance_of(UserPolicy).to receive(:destroy?) { |instance|
        @called = true
        original.bind(instance).call
      }
    end

    it "calls after_policy_authorize callbacks" do
      expect_any_instance_of(UserResource).to receive(:test) {
        expect(@called).to be true
      }

      do_request
    end
  end
end
