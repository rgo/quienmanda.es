class WelcomeController < ApplicationController
  etag { can? :manage, Entity } # Don't cache admin content together with the rest

  def index    
    # Highlight manually curated articles in the frontpage
    @highlights = Post.where(featured: true).includes(:photo).order("published_at desc")
    @highlights = @highlights.published() unless can? :manage, Post

    # Show the latests posts...
    @posts = (can? :manage, Post) ? Post.all : Post.published
    @posts = @posts.where(featured: false).includes(:photo).order("published_at DESC").limit(4)

    # ...and photos
    @photos = (can? :manage, Photo) ? Photo.all : Photo.published
    @photos = @photos.order("updated_at DESC").limit(6)
 
    fresh_when  last_modified: [@highlights.maximum(:published_at), 
                                @posts.maximum(:published_at), 
                                @photos.maximum(:updated_at)].max, 
                public: current_user.nil?
  end
end
