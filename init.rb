# This file is a part of Redmine Tags (redmine_tags) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2026 RedmineUP
# http://www.redmineup.com/
#
# redmine_tags is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_tags is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_tags.  If not, see <http://www.gnu.org/licenses/>.

requires_redmineup version_or_higher: '1.1.10' rescue raise "\n\033[31mRedmine requires newer redmineup gem version.\nPlease update with 'bundle update redmineup'.\033[0m"

require 'redmine'

TAGS_VERSION_NUMBER = '2.1.2'
TAGS_VERSION_TYPE = 'Light version'

Redmine::Plugin.register :redmineup_tags do
  name "Redmine Tags plugin (#{TAGS_VERSION_TYPE})"
  author 'RedmineUP'
  description 'Redmine issues tagging support with multiple tag clouds'
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
  }, partial: 'tags/settings'

  # Permissions for Tag Clouds
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

# Patch for adding tab to Project Settings
module RedmineupTags
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.class_eval do
          alias_method :project_settings_tabs_without_tags, :project_settings_tabs

          def project_settings_tabs
            tabs = project_settings_tabs_without_tags
            unless tabs.any? { |tab| tab[:name] == 'tags' }
              tabs << {
                name: 'tags',
                action: :plugin,
                partial: 'tags/settings',
                label: :tags
              }
            end
            tabs
          end
        end
      end
    end
  end
end

# Apply patch
unless ProjectsHelper.included_modules.include?(RedmineupTags::Patches::ProjectsHelperPatch)
  ProjectsHelper.include RedmineupTags::Patches::ProjectsHelperPatch
end

if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk
  Rails.autoloaders.each { |loader| loader.ignore(File.dirname(__FILE__) + '/lib') }
end

require File.dirname(__FILE__) + '/lib/redmineup_tags'

ActiveSupport.on_load(:action_view) do
  include TagsHelper
end