class TagCloud < ActiveRecord::Base
  belongs_to :project
  belongs_to :created_by, class_name: 'User'

  # Правильный синтаксис для Rails 8
  serialize :status_filter, Array
  serialize :version_filter, Array
  serialize :tracker_filter, Array

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :project, presence: true

  default_scope { order(:position, :id) }

  def is_system?
    is_system == true
  end
end