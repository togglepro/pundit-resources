require "rails_helper"

RSpec.describe PostsController, type: :controller do
  describe "#update_relationship" do
    let(:params) {{
      relationship: "user",
      post_id: post_id,
      data: {
        type: "users",
        id: user_id.to_s,
      },
    }}

    def do_request
      patch :update_relationship, params_hash(params)
    end

    context "when the post does not exist" do
      let(:user_id) { User.create!.id }
      let(:post_id) { next_id Post }
      before { do_request }

      it "responds with 404 Not Found" do
        expect(response).to have_http_status 404
      end
    end

    context "when the post exists" do
      let!(:post) { Post.create! }
      let(:post_id) { post.id }

      let!(:user) { User.create! }
      let(:user_id) { user.id }

      context "but Pundit does not allow updating the post" do
        before do
          allow_any_instance_of(PostPolicy).
            to receive(:update?).and_return(false)
          do_request
        end

        it "responds with 404 Forbidden" do
          expect(response).to have_http_status 403
        end
      end

      context "and Pundit allows updating the post" do
        before do
          allow_any_instance_of(PostPolicy).
            to receive(:update?).and_return(true)
          do_request
        end

        it "responds with 204 No Content" do
          expect(response).to have_http_status 204
        end

        it "updates post" do
          expect(post.reload.user).to eq user
        end
      end
    end
  end
end
