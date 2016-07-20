require "rails_helper"

RSpec.describe UserResource do

  let(:model) { User.new }
  let(:context) { Hash.new }

  let(:resource) { described_class.new(model, context) }
  subject { resource }

  describe "to-one relationships" do
    specify "can use non-ActiveRecord associations" do
      expect(subject.post._model.title).to start_with "Hello"
    end
  end

end
