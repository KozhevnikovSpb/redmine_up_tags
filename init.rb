Redmine::Plugin.register :redmineup_tags do
  name "Redmine Tags plugin (#{TAGS_VERSION_TYPE})"
  author 'RedmineUP'
  description 'Redmine issues tagging support'
  version TAGS_VERSION_NUMBER
  url 'https://www.redmineup.com/pages/plugins/tags/'
  author_url 'mailto:support@redmineup.com'

  requires_redmine version_or_higher: '4.0'

  settings default: {
    sidebar_tag_list_view: 'none',
    issues_show_count: 0,
    issues_open_only: 0,
    issues_sort_by: 'name',
    use_colors: 1,
    issues_sort_order: 'asc',
    tags_suggestion_order: 'name'
  }, partial: 'tags/settings'   # ← Оставляем оригинальный partial плагина

  # Добавляем permissions для Tag Clouds
  project_module :tags do
    permission :manage_tag_clouds, {
      tag_clouds: [:index, :new, :create, :edit, :update, :destroy]
    }, require: :member
    permission :select_tag_clouds, {
      tag_clouds: [:toggle_visibility]
    }
  end

  menu :admin_menu, :tags, { controller: 'settings', action: 'plugin', id: 'redmineup_tags' }, caption: :tags, html: { class: 'icon' }, icon: 'tag', plugin: :redmineup_tags
end