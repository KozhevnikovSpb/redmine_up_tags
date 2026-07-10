module IssuesTagsHelper
  def sidebar_tags
    return @sidebar_tags if defined?(@sidebar_tags)

    @sidebar_tags = []
    return @sidebar_tags unless @project && RedmineupTags.tag_list_view != :none

    projects = [@project]
    projects.concat(@project.descendants.to_a) if Setting.display_subprojects_issues?

    @sidebar_tags = Issue.all_tags(
      projects: projects,
      user: User.current,
      open_only: RedmineupTags.settings['issues_open_only'].to_i == 1
    ).to_a
  rescue StandardError => e
    log_tag_sidebar_error(e, 'system cloud tags')
    @sidebar_tags = []
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
    tags = TagCloudAggregator.new(cloud, user: User.current).tags.to_a
    render_tags_list(
      tags,
      show_count: RedmineupTags.settings['issues_show_count'].to_i == 1,
      open_only: false,
      style: RedmineupTags.tag_list_view
    )
  rescue StandardError => e
    log_tag_sidebar_error(e, "custom cloud #{cloud.id}")
    ''.html_safe
  end

  def render_tags_sidebar
    return ''.html_safe unless @project && RedmineupTags.tag_list_view != :none

    clouds = TagCloud.unscoped.where(project_id: @project.id).order(:position, :id).to_a
    system_cloud = clouds.detect(&:is_system?)
    sections = []

    if system_cloud.nil? || system_cloud.visible_for?(User.current)
      sections << tag_cloud_section(
        system_cloud&.name || l(:tags),
        render_sidebar_tags,
        'sidebar-tag-cloud sidebar-tag-cloud-system'
      )
    end

    clouds.reject(&:is_system?).each do |cloud|
      next unless cloud.visible_for?(User.current)

      extra = nil
      if User.current.allowed_to?(:select_tag_clouds, @project)
        extra = content_tag(:p, class: 'small') do
          link_to(
            l(:button_hide),
            toggle_project_tag_cloud_preference_path(@project, cloud),
            method: :post,
            class: 'icon icon-close'
          )
        end
      end

      sections << tag_cloud_section(
        cloud.name,
        render_tag_cloud(cloud),
        'sidebar-tag-cloud',
        data: { tag_cloud_id: cloud.id },
        extra: extra
      )
    end

    safe_join(sections)
  rescue StandardError => e
    log_tag_sidebar_error(e, 'sidebar')
    ''.html_safe
  end

  private

  def tag_cloud_section(title, body, css_class, data: nil, extra: nil)
    options = { class: css_class }
    options[:data] = data if data

    content_tag(:div, options) do
      safe_join([
        content_tag(:h3, title),
        body,
        extra
      ].compact)
    end
  end

  def log_tag_sidebar_error(error, context)
    project_id = @project&.id || 'none'
    user_id = User.current&.id || 'anonymous'
    Rails.logger.error(
      "[redmineup_tags] Failed to render #{context} " \
      "(project=#{project_id}, user=#{user_id}): #{error.class}: #{error.message}"
    )
  end
end
