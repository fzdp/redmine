class FileImportJob
  include Sidekiq::Job

  def perform(opts)
    options = opts.symbolize_keys
    options[:job_id] = self.jid
    ::Excel::ImportExcelService.call(options)
  end
end