module RedmineupTags
  module Patches
    module TimeEntryQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method :statement_without_redmine_tags, :statement
          alias_method :statement, :statement_with_redmine_tags
          alias_method :available_filters_without_redmine_tags, :available_filters
          alias_method :available_filters, :available_filters_with_redmine_tags
          add_available_column QueryTagsColumn.new(:tags_relations, caption: :tags)
        end
      end

      module InstanceMethods
        def statement_with_redmine_tags
          filter = filters.delete('issue_tags')
          clauses = statement_without_redmine_tags || ''
          return clauses unless filter

          filters['issue_tags'] = filter
          issues = Issue.all
          operator = operator_for('issue_tags')
          issues =
            case operator
            when '=', '!'
              issues.tagged_with(values_for('issue_tags').clone, match_all: true)
            when '!*'
              issues.joins(:tags).distinct
            else
              issues.joins(:tags).distinct
            end

          compare = operator.include?('!') ? 'NOT IN' : 'IN'
          clauses << ' AND ' unless clauses.empty?
          clauses << "(#{TimeEntry.table_name}.issue_id #{compare} (#{issues.select(:id).to_sql}))"
          clauses
        ensure
          filters['issue_tags'] = filter if filter
        end

        def available_filters_with_redmine_tags
          available_filters_without_redmine_tags
          selected_tags = []
          if filters['issue_tags'].present?
            selected_tags = Issue.all_tags(project: project, user: User.current)
                                 .where(name: filters['issue_tags'][:values])
                                 .map { |tag| [tag.name, tag.name] }
          end
          add_available_filter('issue_tags', type: :issue_tags, name: l(:tags), values: selected_tags)
        end
      end
    end
  end
end

if (ActiveRecord::Base.connection.tables.include?('queries') rescue false) &&
   TimeEntryQuery.included_modules.exclude?(RedmineupTags::Patches::TimeEntryQueryPatch)
  TimeEntryQuery.send(:include, RedmineupTags::Patches::TimeEntryQueryPatch)
end
