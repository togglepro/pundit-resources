require "rails_helper"

RSpec.describe UsersController, type: :controller do
  describe "#update" do
    def do_request
      data = { id: id, type: "users", attributes: { "created-at": Time.now } }
      patch :update, params_hash(id: id, data: data)
    end

    before do
      request.headers["Content-Type"] = "application/vnd.api+json"
    end

    context "when the user does not exist" do
      let(:id) { next_id User }

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
end
