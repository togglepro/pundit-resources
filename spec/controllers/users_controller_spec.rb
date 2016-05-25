require "rails_helper"

# This spec tests that a correctly configured controller and resource pair
# will automatically use Pundit policies.
RSpec.describe UsersController, type: :controller do
  render_views

  it { is_expected.to be_a JSONAPI::ResourceController }
  it { is_expected.to be_a Pundit::ResourceController }

  let(:body) { JSON.parse(response.body, symbolize_names: true) }

  describe "#index" do
    # Make sure there are multiple users in the database,
    # and select one at random that will feature in the random scope
    # returned by the policy.
    let!(:user) { 3.times.map { User.create! }.sample }

    before do
      # Stub policy to return a random scope that could only result from here
      expect_any_instance_of(UserPolicy::Scope).
        to receive(:resolve).and_return(User.where(id: user.id))

      get :index
    end

    it "uses the Pundit scope" do
      unless response.status == 200
        body[:errors].each do |error|
          puts error[:meta][:exception]
          puts error[:meta][:backtrace]
        end
        fail "Expected 200 OK but was #{response.status}"
      end

      expect(body[:data].count).to eq 1
      expect(body.dig(:data, 0, :id)).to eq user.id.to_s
    end
  end

  describe "#create" do
    def do_request
      post :create, params: { data: { type: :users } }
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

  describe "#show" do
    def do_request
      get :show, params: { id: id }
    end

    context "when the user does not exist" do
      let(:id) { User.order(:id).select(:id).first&.id.to_i + 1 }

      before { do_request }

      it "responds with 404 Not Found" do
        expect(response).to have_http_status 404
      end
    end

    context "when the user exists" do
      let!(:user) { User.create! }
      let(:id) { user.id }

      it "uses the scope instead of calling #show?" do
        expect_any_instance_of(UserPolicy::Scope).to receive(:resolve)
        do_request
      end

      context "but Pundit says no" do
        before do
          allow_any_instance_of(UserPolicy::Scope).
            to receive(:resolve).and_return(User.none)
          do_request
        end

        # Even though the resource exists, it is still correct to respond with
        # 404 Not Found because the client shouldn't be able to determine
        # whether a given resource exists.
        #
        # From RFC 2616:
        #
        # > If the server does not wish to make this information available to
        # > the client, the status code 404 (Not Found) can be used instead.
        it "responds with 404 Not Found" do
          expect(response).to have_http_status 404
          expect(body[:errors].count).to eq 1
        end
      end

      context "and Pundit says yes" do
        before do
          allow_any_instance_of(UserPolicy::Scope).
            to receive(:resolve).and_return(User.all)
          do_request
        end

        it "responds with 200 OK" do
          expect(response).to have_http_status 200
          expect(body[:data][:id]).to eq user.id.to_s
        end
      end
    end
  end

  describe "#update" do
    def do_request
      data = { id: id, type: "users", attributes: { "created-at": Time.now } }
      patch :update, params: { id: id, data: data }
    end

    before do
      request.headers["Content-Type"] = "application/vnd.api+json"
    end

    context "when the user does not exist" do
      let(:id) { User.order(:id).select(:id).first&.id.to_i + 1 }

      before { do_request }

      it "responds with 404 Not Found" do
        expect(response).to have_http_status 404
      end
    end

    context "when the user exists" do
      let!(:user) { User.create! }
      let(:id) { user.id }

      it "uses the scope instead of calling #update?" do
        expect_any_instance_of(UserPolicy::Scope).to receive(:resolve)
        do_request
      end

      # This should return 404 when the user can't see the resource,
      # but 403 when it can.
      context "but Pundit says no" do
        before do
          allow_any_instance_of(UserPolicy).
            to receive(:update?).and_return(false)
        end

        context "when the user is not included in the scope" do
          before do
            allow_any_instance_of(UserPolicy::Scope).
              to receive(:resolve).and_return(User.none)
            do_request
          end

          # Even though the resource exists, it is still correct to respond with
          # 404 Not Found because the client shouldn't be able to determine
          # whether a given resource exists.
          #
          # From RFC 2616:
          #
          # > If the server does not wish to make this information available to
          # > the client, the status code 404 (Not Found) can be used instead.
          it "responds with 404 Not Found" do
            expect(response).to have_http_status 404
          end

          it "contains an error in the JSON response" do
            expect(body[:errors].count).to eq 1
          end
        end

        context "when the user is included in the scope" do
          before do
            allow_any_instance_of(UserPolicy::Scope).
              to receive(:resolve).and_return(User.all)
            do_request
          end

          it "responds with 403 Forbidden" do
            expect(response).to have_http_status 403
          end

          it "contains an error in the JSON response" do
            expect(body[:errors].count).to eq 1
            expect(body.dig(:errors, 0, :title)).to eq "Update Forbidden"
            expect(body.dig(:errors, 0, :detail)).to eq <<-DESC.strip
              You don't have permission to update this user.
            DESC
          end
        end
      end

      context "and Pundit says yes" do
        before do
          allow_any_instance_of(UserPolicy).
            to receive(:update?).and_return(true)
          do_request
        end

        it "responds with 200 OK" do
          expect(response).to have_http_status 200
          expect(body[:data][:id]).to eq user.id.to_s
        end
      end
    end
  end

  describe "#destroy" do
    def do_request
      delete :destroy, params: { id: id }
    end

    context "when the user does not exist" do
      let(:id) { User.order(:id).select(:id).first&.id.to_i + 1 }

      before { do_request }

      it "responds with 404 Not Found" do
        expect(response).to have_http_status 404
      end
    end

    context "when the user exists" do
      let!(:user) { User.create! }
      let(:id) { user.id }

      context "but Pundit says no" do
        before do
          allow_any_instance_of(UserPolicy).
            to receive(:destroy?).and_return(false)
        end

        context "when the user is not included in the scope" do
          before do
            allow_any_instance_of(UserPolicy::Scope).
              to receive(:resolve).and_return(User.none)
            do_request
          end

          # Even though the resource exists, it is still correct to respond with
          # 404 Not Found because the client shouldn't be able to determine
          # whether a given resource exists.
          #
          # From RFC 2616:
          #
          # > If the server does not wish to make this information available to
          # > the client, the status code 404 (Not Found) can be used instead.
          it "responds with 404 Not Found" do
            expect(response).to have_http_status 404
          end

          it "contains an error in the JSON response" do
            expect(body[:errors].count).to eq 1
          end
        end

        context "when the user is included in the scope" do
          before do
            allow_any_instance_of(UserPolicy::Scope).
              to receive(:resolve).and_return(User.all)
            do_request
          end

          it "responds with 403 Forbidden" do
            expect(response).to have_http_status 403
          end

          it "contains an error in the JSON response" do
            expect(body[:errors].count).to eq 1
            expect(body.dig(:errors, 0, :title)).to eq "Destroy Forbidden"
            expect(body.dig(:errors, 0, :detail)).to eq <<-DESC.strip
              You don't have permission to destroy this user.
            DESC
          end
        end
      end

      context "and Pundit says yes" do
        before do
          allow_any_instance_of(UserPolicy).
            to receive(:destroy?).and_return(true)
        end

        it "destroys the user" do
          expect { do_request }.to change { User.count }.by(-1)
        end

        it "responds with 204 No Content" do
          do_request
          expect(response).to have_http_status 204
        end
      end
    end
  end
end
