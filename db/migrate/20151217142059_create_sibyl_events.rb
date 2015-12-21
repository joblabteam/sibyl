class CreateSibylEvents < ActiveRecord::Migration
  def change
    create_table :sibyl_events do |t|
      t.string :kind, null: false, index: true
      t.datetime :occurred_at, null: false, index: true
      t.jsonb :data, null: false, default: '{}'
      t.datetime :created_at, null: false
    end

    add_index  :sibyl_events, :data, using: :gin
  end
end
