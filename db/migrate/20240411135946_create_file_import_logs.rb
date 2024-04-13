class CreateFileImportLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :file_import_logs do |t|
      t.references :user
      t.integer :import_type, default: 0
      t.string :page_url
      t.string :original_file_name
      t.string :file_path
      t.integer :file_type, default: 0
      t.string :file_digest
      t.text :headers
      t.string :job_id
      t.integer :job_status, default: 0
      t.datetime :start_time
      t.datetime :end_time
      t.bigint :processed_count, default: 0
      t.bigint :failed_count, default: 0
    end
  end
end
