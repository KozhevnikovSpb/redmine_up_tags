# This file is a part of Redmine Tags (redmine_tags) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2026 RedmineUP
# http://www.redmineup.com/
#
# redmine_tags is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_tags is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_tags.  If not, see <http://www.gnu.org/licenses/>.

class CreateTags < ActiveRecord::Migration[7.0]

  def self.up
    # Create tags table if not exists (default state for redmine_up_tags Light version)
    unless table_exists?(:tags)
      create_table :tags do |t|
        t.string :name, null: false
        t.integer :color
        t.timestamps
      end
      add_index :tags, :name, unique: true
    end

    # Create taggings table if not exists
    unless table_exists?(:taggings)
      create_table :taggings do |t|
        t.integer :tag_id, null: false
        t.integer :taggable_id, null: false
        t.string :taggable_type, null: false
        t.datetime :created_at
        t.timestamps
      end

      # Indexes for performance (avoid N+1, fast tag aggregation)
      add_index :taggings, :tag_id
      add_index :taggings, [:taggable_id, :taggable_type]
      add_index :taggings, [:tag_id, :taggable_id, :taggable_type], unique: true, name: 'index_taggings_on_tag_and_taggable'
    end

    # Optional: MySQL collation fix for proper tag name comparison (compatibility with other RedmineUP plugins)
    if defined?(ActiveRecord::Base) && ActiveRecord::Base.connection.adapter_name.downcase.include?('mysql')
      execute "ALTER TABLE tags MODIFY name varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;" rescue nil
    end
  end

  def self.down
    drop_table :taggings, if_exists: true
    drop_table :tags, if_exists: true
  end
end
