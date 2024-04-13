class Excel::ImportExcelService < ApplicationService
  VALID_KEYS = %i(file_path import_type page_url original_name user_id project_id job_id row_handler file_type max_row)
  MAX_ROW = 500000
  private_constant :VALID_KEYS

  attr_reader :options, :max_row

  def initialize(opts = {})
    @options = opts.symbolize_keys.slice *VALID_KEYS
    if @options[:max_row].present?
      @max_row = [options[:max_row].to_i, MAX_ROW].min
    else
      @max_row = MAX_ROW
    end
  end

  def call
    check_options!
    handler_service = get_row_handler!
    create_log

    begin
      @_handler = handler_service.new(user_id: options[:user_id], project_id: options[:project_id], log_id: @log.id)
      first_row = true

      SimpleXlsxReader.open(options[:file_path]).sheets.first.rows.each.with_index do |cells, i|
        if first_row
          @log.save_headers cells
          first_row = false
          next
        end

        break if i > max_row

        res = @_handler.__send__(:call, cells)
        if res.success
          handle_row_success
        else
          handle_row_fail(i, cells, res.message)
        end

        puts "============= res ============"
        puts res
      end
    rescue => e
      handle_job_exit
      raise e.message
    end

    handle_job_done
  end

  private

  def check_options!
    raise "user_id not exist" if options[:user_id].blank?
    raise "file path not exist" if options[:file_path].blank? || !File.exist?(options[:file_path])
    raise "invalid import_type" unless FileImportLog.import_types.key?(options[:import_type])
  end

  def create_log
    file_digest = Digest::MD5.file(options[:file_path]).hexdigest
    file_type = options[:file_type] || FileImportLog.file_types[:xlsx]
    @log ||= FileImportLog.create!(
      user_id: options[:user_id], import_type: options[:import_type], page_url: options[:page_url],
      original_file_name: options[:original_name], file_path: options[:file_path], project_id: options[:project_id],
      file_digest: file_digest, job_id: options[:job_id], start_time: DateTime.now, file_type: file_type
    )
    @log.processing!
    @log.cache_processing
  end

  def get_row_handler!
    handler_service = (options[:row_handler] || "Excel::RowHandler::#{options[:import_type].camelcase}RowHandlerService").safe_constantize
    raise "row handler not found" if handler_service.nil?
    raise "#{handler_service}#call method not found" unless handler_service.instance_methods(false).include?(:call)
    handler_service
  end

  def handle_job_exit
    @log.cache_exit
    @log.finish_del_cached
  end

  def handle_job_done
    @log.cache_done
    @log.finish_del_cached
  end

  def handle_row_success
    @log.incr_cached_process_count
  end

  def handle_row_fail(i, cells, message)
    @log.incr_cached_fail_count
    # todo row fail job
  end
end