class AddProjectIdToFileImportLogs < ActiveRecord::Migration[7.1]
  def change
    add_reference :file_import_logs, :project
  end
end
