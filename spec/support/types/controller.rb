RSpec.shared_context "controller specs", type: :controller do
  render_views

  let(:body) { JSON.parse(response.body, symbolize_names: true) }

  def params_hash(inner_hash)
    if Rails.version.split(?.).first.to_i < 5
      inner_hash
    else
      { params: inner_hash }
    end
  end
end
