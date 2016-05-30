require "rails_helper"

RSpec.describe UsersController, type: :controller do
  describe "#show" do
    def do_request
      get :show, params_hash(id: id)
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
end
