class FileImportFailRow < ApplicationRecord
  serialize :cells
  serialize :messages
end