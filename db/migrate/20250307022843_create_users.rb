class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false, limit: 100

      t.timestamps
    end

    # Add an index on name for potential future searches
    add_index :users, :name
  end
end
