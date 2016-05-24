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
end
