class TagCloud < ActiveRecord::Base
  belongs_to :project
  belongs_to :created_by, class_name: 'User'

  # Rails 8 compatible serialization
  attribute :status_filter, :json
  attribute :version_filter, :json
  attribute :tracker_filter, :json

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :project, presence: true

  default_scope { order(:position, :id) }

  def is_system?
    is_system == true
  end
end