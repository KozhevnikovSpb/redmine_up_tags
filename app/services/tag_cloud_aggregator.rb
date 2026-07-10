class TagCloudAggregator
  def initialize(tag_cloud, user: User.current)
    @tag_cloud = tag_cloud
    @project = tag_cloud.project
    @user = user
  end

  def tags
    issues = Issue.visible(@user, project: @project, with_subprojects: false)
    issues = issues.where(status_id: @tag_cloud.status_filter) if @tag_cloud.status_filter.present?
    issues = issues.where(tracker_id: @tag_cloud.tracker_filter) if @tag_cloud.tracker_filter.present?
    issues = issues.where(fixed_version_id: @tag_cloud.version_filter) if @tag_cloud.version_filter.present?

    tags_table = Redmineup::Tag.table_name
    taggings_table = Redmineup::Tagging.table_name

    Redmineup::Tag
      .joins("INNER JOIN #{taggings_table} ON #{taggings_table}.tag_id = #{tags_table}.id")
      .where("#{taggings_table}.taggable_type = ?", Issue.name)
      .where("#{taggings_table}.taggable_id IN (#{issues.select(:id).to_sql})")
      .select(
        "#{tags_table}.id, #{tags_table}.name, #{tags_table}.color, " \
        "COUNT(DISTINCT #{taggings_table}.taggable_id) AS count"
      )
      .group("#{tags_table}.id, #{tags_table}.name, #{tags_table}.color")
  end
end
