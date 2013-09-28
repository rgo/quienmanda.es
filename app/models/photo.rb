class Photo < ActiveRecord::Base
  has_many :annotations, dependent: :delete_all
  has_many :related_entities, through: :annotations, source: :entity

  has_many :posts_as_header, class_name: Post # It can be used as header in many posts

  has_many :mentions, as: :mentionee, inverse_of: :mentionee, dependent: :delete_all
  has_many :related_posts, -> { order('updated_at desc') }, through: :mentions, source: :post

  has_paper_trail

  include PgSearch
  multisearchable :against => [:footer], :if => :published?

  mount_uploader :file, PhotoUploader

  acts_as_taggable

  scope :published, -> { where(published: true) }
end
