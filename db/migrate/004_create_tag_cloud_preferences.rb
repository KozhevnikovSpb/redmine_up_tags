class CreateTagCloudPreferences < ActiveRecord::Migration[7.0]
  class MigrationTagCloud < ActiveRecord::Base
    self.table_name = 'tag_clouds'
  end

  def up
    create_table :tag_cloud_preferences do |t|
      t.references :tag_cloud, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.boolean :visible, null: false, default: true
      t.timestamps
    end

    add_index :tag_cloud_preferences,
              %i[tag_cloud_id user_id],
              unique: true,
              name: 'index_tag_cloud_preferences_unique'

    backfill_system_clouds
  end

  def down
    drop_table :tag_cloud_preferences
  end

  private

  def backfill_system_clouds
    return unless table_exists?(:projects) && table_exists?(:tag_clouds)

    now = Time.current
    select_values('SELECT id FROM projects').each do |project_id|
      next if MigrationTagCloud.where(project_id: project_id, is_system: true).exists?

      MigrationTagCloud.create!(
        project_id: project_id,
        name: 'Default Tags',
        visible_by_default: true,
        is_system: true,
        position: 0,
        created_at: now,
        updated_at: now
      )
    end
  end
end
