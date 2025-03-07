class CreateSleepRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :sleep_records do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :start_time, null: false
      t.datetime :end_time
      t.integer :duration_minutes

      t.timestamps
    end

    # Add indexes for common queries
    add_index :sleep_records, [:user_id, :created_at]
    add_index :sleep_records, [:user_id, :start_time]
    add_index :sleep_records, [:start_time, :end_time]
  end
end
