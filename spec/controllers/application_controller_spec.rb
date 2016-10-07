require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  it { is_expected.to be_a JSONAPI::ResourceController }
  it { is_expected.to be_a Pundit::ResourceController }
end
