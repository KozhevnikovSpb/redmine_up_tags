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

require_dependency 'queries_helper'
require_dependency 'issue_queries_query' if ActiveSupport::Dependencies::search_for_file('issue_queries_helper')

module RedmineupTags
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :column_value_without_tags, :column_value
          alias_method :column_value, :column_value_with_tags

          if method_defined?(:sidebar_queries)
            alias_method :sidebar_queries_without_redmineup_tags, :sidebar_queries
            alias_method :sidebar_queries, :sidebar_queries_with_redmineup_tags
          end
        end
      end

      module InstanceMethods
        include TagsHelper

        def column_value_with_tags(column, list_object, value)
          if column.name == :tags_relations && list_object.is_a?(Issue)
            [value].flatten.collect { |tag| render_issue_tag_link(tag) }
                   .join(RedmineupTags.use_colors? ? ' ' : ', ')
                   .html_safe
          else
            column_value_without_tags(column, list_object, value)
          end
        end

        # Redmine normally loads sidebar queries with the SQL-backed .visible
        # scope. On the supported Redmine 7 / Rails 8 combination that scope
        # can return an empty result even though individual queries pass the
        # same visibility check. Preserve the native path first, then use the
        # model's visible? method as a security-equivalent compatibility
        # fallback for IssueQuery only.
        def sidebar_queries_with_redmineup_tags(klass, project)
          return sidebar_queries_without_redmineup_tags(klass, project) unless klass == IssueQuery

          project ||= @project
          native_queries = klass.visible(User.current)
                                .global_or_on_project(project)
                                .sorted
                                .to_a
          return native_queries if native_queries.any?

          fallback_queries = klass.global_or_on_project(project)
                                  .sorted
                                  .to_a
                                  .select { |query| query.visible?(User.current) }

          if fallback_queries.any?
            Rails.logger.warn(
              "[redmineup_tags] Native IssueQuery.visible scope returned no sidebar queries; " \
              "restored #{fallback_queries.size} queries with per-record visibility checks " \
              "(project=#{project&.id || 'global'}, user=#{User.current&.id || 'anonymous'})"
            )
          end

          fallback_queries
        rescue StandardError => e
          Rails.logger.error(
            "[redmineup_tags] Failed to build saved-query sidebar: #{e.class}: #{e.message}"
          )
          sidebar_queries_without_redmineup_tags(klass, project)
        end
      end
    end
  end
end

base = ActiveSupport::Dependencies::search_for_file('issue_queries_helper') ? IssueQueriesHelper : QueriesHelper
unless base.included_modules.include?(RedmineupTags::Patches::QueriesHelperPatch)
  base.send(:include, RedmineupTags::Patches::QueriesHelperPatch)
end
