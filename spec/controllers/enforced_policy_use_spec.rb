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

  before do
    class << @controller
      include ActionController::Head

      # override #index to allow easy testing with different response codes
      def index
        head params[:response_status]
      end
    end
  end

  def do_request(params = {})
    get :index, params_hash(params)
  end

  context "when the policy callback is not called" do
    context "when the response is an error" do
      before do
        do_request(response_status: code)
      end

      context "in the 4xx range" do
        let(:code) { rand(400...500) }

        it "does not raise an exception" do
          expect(response).to have_http_status code
        end
      end

      context "in the 5xx range" do
        let(:code) { rand(400...500) }

        it "does not raise an exception" do
          expect(response).to have_http_status code
        end
      end
    end

    context "when the response is not an error" do
      let(:error) { Pundit::AuthorizationNotPerformedError }

      context "and is in the 2xx range" do
        let(:code) { rand(200...300) }

        it "raises an exception" do
          expect { do_request(response_status: code) }.to raise_error error
        end
      end

      context "and is in the 3xx range" do
        let(:code) { rand(300...400) }

        it "raises an exception" do
          expect { do_request(response_status: code) }.to raise_error error
        end
      end
    end
  end

  context "when the policy callback is called" do
    before do
      @controller.send(:context)[:policy_used].call
    end

    it "responds with 200 OK" do
      do_request
      expect(response).to have_http_status 200
    end
  end
end
