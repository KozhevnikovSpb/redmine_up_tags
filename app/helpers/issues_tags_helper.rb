module IssuesTagsHelper
  def sidebar_tags
    return @sidebar_tags if defined?(@sidebar_tags)

    @sidebar_tags = []
    projects = [@project] + (@project && Setting.display_subprojects_issues? ? @project.descendants : [])
    if RedmineupTags.tag_list_view != :none
      @sidebar_tags = Issue.available_tags(
        project: @project,
        projects: projects,
        open_only: RedmineupTags.settings['issues_open_only'].to_i == 1
      )
    end
    @sidebar_tags.to_a
  end

  def render_sidebar_tags
    render_tags_list(
      sidebar_tags,
      show_count: RedmineupTags.settings['issues_show_count'].to_i == 1,
      open_only: RedmineupTags.settings['issues_open_only'].to_i == 1,
      style: RedmineupTags.tag_list_view
    )
  end

  def render_tag_cloud(cloud)
    tags = TagCloudAggregator.new(cloud, user: User.current).tags
    render_tags_list(
      tags,
      show_count: RedmineupTags.settings['issues_show_count'].to_i == 1,
      open_only: false,
      style: RedmineupTags.tag_list_view
    )
  end
end
