require "rails_helper"

RSpec.describe PostsController, type: :controller do
  describe "#get_related_resources" do
    let(:params) {{
      source: "users",
      relationship: "posts",
      user_id: user_id,
    }}

    def do_request
      get :get_related_resources, params_hash(params)
    end

    describe "when the user does not exist" do
      let(:user_id) { next_id User }

      before { do_request }

      it "responds with 404 Not Found" do
        expect(response).to have_http_status 404
      end
    end

    describe "when the user exists" do
      let(:user) { User.create! }
      let(:user_id) { user.id }
      let(:posts) { 4.times.map { Post.create! } }

      before do
        posts.first(2).map { |p| p.update!(user: user) }

        expect_any_instance_of(UserPolicy::Scope).
          to receive(:resolve).and_return(User.all)

        # Make the scope return one post that belongs to the user
        # and one that does not, so it can be tested that only the ones that
        # belong to the user are eventually returned.
        expect_any_instance_of(PostPolicy::Scope).to receive(:resolve).
          and_return(Post.where(id: posts.values_at(1, 3).map(&:id)))

        do_request
      end

      it "responds with 200 OK" do
        expect(response).to have_http_status 200
      end

      it "uses the pundit scope and returns only those belonging to the user" do
        expect(body[:data].map { |l| l[:id] }).to eq [posts[1].id.to_s]
      end
    end
  end
end
