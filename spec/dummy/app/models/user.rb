class User < ApplicationRecord
  def x_post
    Post.find_or_create_by!(title: "Hello")
  end
end
