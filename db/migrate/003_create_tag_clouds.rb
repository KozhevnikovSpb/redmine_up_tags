class CreateTagClouds < ActiveRecord::Migration[6.1]  # или [5.2]/[7.0] в зависимости от версии Redmine
  def change
    create_table :tag_clouds do |t|
      t.references :project, null: false, foreign_key: true, index: true

      t.string :name, null: false

      # Serialized filters (в Redmine часто используют text + serialize в модели)
      t.text :status_filter
      t.text :version_filter
      t.text :tracker_filter

      t.boolean :visible_by_default, default: true, null: false

      t.integer :position, default: 0, null: false

      t.boolean :is_system, default: false, null: false

      t.references :created_by, null: true, foreign_key: { to_table: :users }, index: true

      t.timestamps
    end

    # Дополнительные индексы для производительности
    add_index :tag_clouds, [:project_id, :is_system]
    add_index :tag_clouds, [:project_id, :position]
    add_index :tag_clouds, [:project_id, :name], unique: true  # чтобы имена были уникальными в рамках проекта
  end
end

