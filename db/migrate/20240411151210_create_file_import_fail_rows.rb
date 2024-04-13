class CreateFileImportFailRows < ActiveRecord::Migration[7.1]
  def change
    create_table :file_import_fail_rows do |t|
      t.references :file_import_log
      t.bigint :row_num, index: true
      t.text :cells
      t.text :messages
      t.timestamps
    end
  end
end
