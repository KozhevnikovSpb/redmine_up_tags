class TagCloud < ActiveRecord::Base
  belongs_to :project
  belongs_to :created_by, class_name: 'User'

  # Новый синтаксис для Rails 8
  serialize :status_filter, coder: Array
  serialize :version_filter, coder: Array
  serialize :tracker_filter, coder: Array

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :project, presence: true

  default_scope { order(:position, :id) }

  def is_system?
    is_system == true
  end
end