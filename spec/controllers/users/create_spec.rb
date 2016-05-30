require "rails_helper"

RSpec.describe UsersController, type: :controller do
  describe "#create" do
    def do_request
      post :create, params_hash(data: { type: :users })
    end

    before do
      request.headers["Content-Type"] = "application/vnd.api+json"
    end

    context "but Pundit says no" do
      before do
        expect_any_instance_of(UserPolicy).
          to receive(:create?).and_return(false)
      end

      it "does not create a user" do
        expect { do_request }.not_to change { User.count }
      end

      it "responds with 403 Forbidden" do
        do_request
        expect(response).to have_http_status 403
        expect(body.dig(:errors, 0, :title)).to eq "Create Forbidden"
        expect(body.dig(:errors, 0, :detail)).to eq <<-DESC.strip
          You don't have permission to create this user.
        DESC
      end
    end

    context "and Pundit says yes" do
      before do
        allow_any_instance_of(UserPolicy).to receive(:create?).and_return(true)
      end

      it "creates a user" do
        expect { do_request }.to change { User.count }.by 1
      end

      it "responds with 201 Created" do
        do_request
        expect(response).to have_http_status 201
      end
    end
  end
end
