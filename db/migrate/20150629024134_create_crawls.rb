class CreateCrawls < ActiveRecord::Migration
  def change
    create_table :crawls do |t|
      t.integer :status
      t.string :request_id
      t.float :elapsed_time
      t.string :url
      t.timestamps null: false
    end
  end
end
