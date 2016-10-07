require "rails_helper"

RSpec.describe UsersController, type: :controller do
  describe "#get_related_resource" do
    let(:params) {{
      relationship: "user",
      source: "posts",
      post_id: post_id,
    }}

    def do_request
      get :get_related_resource, params_hash(params)
    end


    context "when the post does not exist" do
      let(:post_id) { next_id Post }
      before { do_request }

      it "responds with 404 Not Found" do
        expect(response).to have_http_status 404
      end
    end

    context "when the post exists" do
      let!(:post) { Post.create! }
      let(:post_id) { post.id }

      context "but the post has no user" do
        before { do_request }

        it "responds with 200 OK" do
          expect(response).to have_http_status 200
        end

        it "does not have user information" do
          expect(body).to eq(data: nil)
        end
      end

      context "and the post has a user" do
        let!(:user) { post.create_user! }
        before { post.save }

        context "and Pundit allows the user to be viewed" do
          before do
            expect_any_instance_of(UserPolicy::Scope).
              to receive(:resolve).and_return(User.all)
            do_request
          end

          it "responds with 200 OK" do
            expect(response).to have_http_status 200
          end

          it "responds with the correct user" do
            expect(body[:data][:id]).to eq user.id.to_s
          end
        end

        context "but Pundit does not allow the user to be viewed" do
          before do
            expect_any_instance_of(UserPolicy::Scope).
              to receive(:resolve).and_return(User.none)
            do_request
          end

          it "responds with 200 OK" do
            expect(response).to have_http_status 200
          end

          it "does not have user information" do
            expect(body).to eq(data: nil)
          end
        end
      end
    end
  end
end
