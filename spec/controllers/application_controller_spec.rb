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

  describe "#show" do
    context "when the user does not exist" do
      let(:id) { User.order(:id).select(:id).first&.id.to_i + 1 }

      before do
        get :show, params: { id: id }
      end

      it "responds with 404 Not Found" do
        expect(response).to have_http_status 404
      end
    end

    context "when the user exists" do
      let!(:user) { User.create! }

      def do_request
        get :show, params: { id: user.id }
      end

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
