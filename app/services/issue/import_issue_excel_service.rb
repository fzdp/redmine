module Issue
  class ImportIssueExcelService < BaseService
    def initialize(opts = {})
      @file_path = opts.values_at(:file_path)
    end

    def call

    end
  end
end