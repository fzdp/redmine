class AddImportLogIdToIssues < ActiveRecord::Migration[7.1]
  def change
    add_reference :issues, :file_import_log
  end
end
