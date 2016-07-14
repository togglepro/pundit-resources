require "rails_helper"

RSpec.describe UsersController, type: :controller do
  describe "#create_relationship" do
    let(:params) {{
      user_id: user_id,
      relationship: "posts",
      data: [{ type: "posts", id: post_id }],
    }}

    let(:user) { User.create! }
    let(:_post) { Post.create! }

    let(:user_id) { user.id }
    let(:post_id) { _post.id }

    def do_request
      post :create_relationship, params_hash(params)
    end

    context "when the user does not exist" do
      let(:user_id) { next_id User }

      before { do_request }

      it "responds with 404 Not Found" do
        expect(response).to have_http_status 404
      end
    end

    context "when the post does not exist" do
      let(:post_id) { next_id Post }

      before { do_request }

      it "responds with 404 Not Found" do
        expect(response).to have_http_status 404
      end
    end

    context "when the user exists" do
      context "but Pundit says no" do
        before do
          Post.destroy_all
          expect_any_instance_of(PostPolicy).
            to receive(:update?).and_return(false)
        end

        it "does not create a post" do
          expect { do_request }.not_to change { user.posts.count }
        end

        it "responds with 403 Forbidden" do
          do_request
          expect(response).to have_http_status 403
          expect(body.dig(:errors, 0, :title)).to eq <<-TITLE.strip
            Create Relationship Forbidden
          TITLE
          expect(body.dig(:errors, 0, :detail)).to eq <<-DESC.strip
            You don't have permission to create relationship this post.
          DESC
        end
      end

      context "and Pundit says yes" do
        before do
          expect_any_instance_of(PostPolicy).
            to receive(:update?).and_return(true)
        end

        it "responds with 204 No Content" do
          do_request
          expect(response).to have_http_status 204
        end

        it "creates a post" do
          expect { do_request }.to change { user.posts.count }.by 1
        end
      end
    end
  end
end
