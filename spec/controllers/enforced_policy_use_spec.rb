require "rails_helper"

RSpec.describe UsersController, type: :controller do
  render_views

  def params_hash(inner_hash)
    if Rails.version < '5.0.0'
      inner_hash
    else
      { params: inner_hash }
    end
  end

  def do_request
    get :show, params_hash(id: User.create!.id)
  end

  context "when the policy callback is not called" do
    before do
      original = UsersController.instance_method(:context)
      expect_any_instance_of(UsersController).to receive(:context) { |instance|
        original.bind(instance).call.merge(policy_used: -> {})
      }
    end

    it "raises an exception" do
      expect { do_request }.to raise_error Pundit::AuthorizationNotPerformedError
    end
  end

  context "when the policy callback is called" do
    it "responds with 200 OK" do
      do_request
      expect(response).to have_http_status 200
    end
  end
end
