class TagCloud < ActiveRecord::Base
  belongs_to :project
  belongs_to :created_by, class_name: 'User'

  serialize :status_filter, Array
  serialize :version_filter, Array
  serialize :tracker_filter, Array

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :project, presence: true

  default_scope { order(:position, :id) }

  before_save :normalize_filters

  def is_system?
    is_system == true
  end

  # Ensures there is always a system/default tag cloud for the project (auto-created on first access or project creation)
  def self.ensure_system_cloud(project)
    return unless project
    system_cloud = project.tag_clouds.where(is_system: true).first
    if system_cloud.nil?
      project.tag_clouds.create!(
        name: I18n.t(:label_default_tag_cloud, default: 'Default Tags'),
        visible_by_default: true,
        is_system: true,
        position: 0,
        created_by: User.current
      )
    end
  end

  private

  def normalize_filters
    [:status_filter, :version_filter, :tracker_filter].each do |attr|
      current = self[attr]
      if current.is_a?(Array)
        self[attr] = current.map { |v| v.to_i }.uniq.reject(&:zero?)
      elsif current.is_a?(String) && current.present?
        self[attr] = current.split(/[,\s]+/).map { |v| v.to_i }.uniq.reject(&:zero?)
      end
    end
  end
end