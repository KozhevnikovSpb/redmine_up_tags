module TagsHelper
  include Redmineup::TagsHelper

  def render_issue_tag_link(tag, options = {})
    filters = [[:issue_tags, '=', tag.name]]
    filters << [:status_id, 'o'] if options[:open_only]
    content =
      if options[:use_search]
        link_to(tag, controller: 'search', action: 'index', id: @project, q: tag.name, wiki_pages: true, issues: true)
      else
        link_to_issue_filter tag.name, filters, project_id: @project
      end
    content << content_tag('span', "(#{tag.count})", class: 'tag-count') if options[:show_count]
    style = RedmineupTags.use_colors? ? { class: 'tag-label-color', style: "background-color: #{tag.color}" } : { class: 'tag-label' }
    content_tag('span', content, style)
  end

  def render_tags_list(tags, options = {})
    return if tags.nil? || tags.empty?

    content = +''
    style = options.delete(:style)
    tags = tags.to_a

    case sorting = "#{RedmineupTags.settings['issues_sort_by']}:#{RedmineupTags.settings['issues_sort_order']}"
    when 'name:asc' then tags.sort_by! { |tag| tag.name.to_s.downcase }
    when 'name:desc' then tags.sort_by! { |tag| tag.name.to_s.downcase }.reverse!
    when 'count:asc' then tags.sort_by! { |tag| tag.count.to_i }
    when 'count:desc' then tags.sort_by! { |tag| tag.count.to_i }.reverse!
    else
      logger.warn "[redmine_tags] Unknown sorting option: <#{sorting}>"
      tags.sort_by! { |tag| tag.name.to_s.downcase }
    end

    list_el, item_el =
      case style
      when :list then %w[ul li]
      when :simple_cloud, :cloud then %w[div span]
      else raise 'Unknown list style'
      end

    content = content.html_safe
    if style == :list && RedmineupTags.settings['issues_sort_by'] == 'name'
      tags.group_by { |tag| tag.name.to_s.downcase.first || '#' }.each do |letter, grouped_tags|
        content << content_tag(item_el, letter.upcase, class: 'letter', style: '')
        add_tags(style, grouped_tags, content, item_el, options)
      end
    else
      add_tags(style, tags, content, item_el, options)
    end

    content_tag(list_el, content, class: 'tags-cloud', style: (style == :simple_cloud ? 'text-align: left;' : ''))
  end

  def link_to_issue_filter(title, filters, options = {})
    options.merge! link_to_issue_filter_options(filters)
    link_to title, options
  end

  def link_to_issue_filter_options(filters)
    options = {
      controller: 'issues',
      action: 'index',
      set_filter: 1,
      fields: [],
      values: {},
      operators: {}
    }

    filters.each do |name, operator, value|
      options[:fields] << name
      options[:operators][name] = operator
      options[:values][name] = [value]
    end
    options
  end

  def tag_cloud_filters_summary(tag_cloud)
    return '' unless tag_cloud

    parts = []
    parts << filter_summary(:field_status, IssueStatus.where(id: tag_cloud.status_filter).sorted.pluck(:name))
    parts << filter_summary(:field_fixed_version, Version.where(id: tag_cloud.version_filter).pluck(:name))
    parts << filter_summary(:field_tracker, Tracker.where(id: tag_cloud.tracker_filter).sorted.pluck(:name))
    safe_join(parts, tag.br)
  end

  private

  def filter_summary(label, values)
    content_tag(:span, "#{l(label)}: #{values.presence&.join(', ') || l(:label_all)}")
  end

  def add_tags(style, tags, content, item_el, options)
    items = []
    tag_cloud tags, (1..8).to_a do |tag, weight|
      items << content_tag(item_el, render_issue_tag_link(tag, options),
                           class: "tag-nube-#{weight}",
                           style: (style == :simple_cloud ? 'font-size: 1em;' : ''))
    end
    separator = style == :simple_cloud ? tag_separator : ' '
    content << safe_join(items, separator)
  end
end
