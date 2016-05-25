RSpec.describe Pundit::ResourceController do
  let(:controller_class) { Class.new { include Pundit::ResourceController } }
  let(:controller) { controller_class.new }

  describe "#context" do
    it "provides the current_user" do
      user = Object.new
      allow(controller).to receive(:current_user).and_return(user)
      expect(controller.send(:context)[:current_user]).to eq user
    end

    it "is protected" do
      expect(controller.protected_methods).to include :context
    end
  end

  context "when included" do
    def config
      JSONAPI.configuration
    end

    def whitelist
      config.exception_class_whitelist
    end

    def include_module
      Class.new(ActionController::Metal) { include Pundit::ResourceController }
    end

    before do
      # Ensure not already there from having been added previously
      config.exception_class_whitelist -= [Pundit::NotAuthorizedError]

      # Add a random value that the module couldn't guess to simulate
      # customised defaults in an application
      whitelist << SecureRandom.hex
    end

    it "adds Pundit::NotAuthorizedError to exception class whitelist when" do
      before = whitelist.dup
      include_module
      expect(whitelist).to eq(before + [Pundit::NotAuthorizedError])

      # Should not be added more than once
      expect { include_module }.not_to change { whitelist.count }
    end
  end
end
