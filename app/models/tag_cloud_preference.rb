class TagCloudPreference < ActiveRecord::Base
  belongs_to :tag_cloud
  belongs_to :user

  validates :user_id, uniqueness: { scope: :tag_cloud_id }
end
