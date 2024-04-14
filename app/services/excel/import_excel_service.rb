class Excel::ImportExcelService < ApplicationService
  VALID_KEYS = %i(file_path import_type page_url original_name user_id project_id job_id row_handler file_type max_row)
  MAX_ROW = 500000
  FAIL_ROW_BATCH_IMPORT_SIZE = 1000
  private_constant :VALID_KEYS

  class FailRowSaveError < StandardError; end

  attr_reader :options, :max_row

  def initialize(opts = {})
    @options = opts.symbolize_keys.slice *VALID_KEYS
    if @options[:max_row].present?
      @max_row = [options[:max_row].to_i, MAX_ROW].min
    else
      @max_row = MAX_ROW
    end
    @fail_row_values = []
  end

  def call
    check_options!
    handler_service = get_row_handler!
    create_import_log

    begin
      @_handler = handler_service.___send__(:new, user_id: options[:user_id], project_id: options[:project_id], log_id: @log.id)
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
      end

      handle_job_done
      success_res(data: { log_id: @log.id })
    rescue => e
      if e.instance_of? FailRowSaveError
        handle_job_fail_rows_error
      else
        handle_job_exit
      end
      raise e.message
    end
  end

  private

  def check_options!
    raise "user_id not exist" if options[:user_id].blank?
    raise "file path not exist" if options[:file_path].blank? || !File.exist?(options[:file_path])
    raise "invalid import_type" unless FileImportLog.import_types.key?(options[:import_type])
  end

  def create_import_log
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
    save_clear_fail_rows if @fail_row_values.present?
    @log.cache_exit
    @log.finish_del_cached
  end

  def handle_job_done
    save_clear_fail_rows if @fail_row_values.present?
    @log.cache_done
    @log.finish_del_cached
  end

  def handle_job_fail_rows_error
    @log.cache_fail_rows_error
    @log.finish_del_cached
  end

  def handle_row_success
    @log.incr_cached_process_count
  end

  def handle_row_fail(i, cells, message)
    @log.incr_cached_fail_count
    @fail_row_values << [@log.id, i, cells, message]
    save_clear_fail_rows if (@fail_row_values.size % FAIL_ROW_BATCH_IMPORT_SIZE).zero?
  end

  def save_clear_fail_rows
    begin
      insert_values = @fail_row_values.map{|arr|Hash[%i(file_import_log_id row_num cells messages).zip(arr)]}
      FileImportFailRow.insert_all!(insert_values)
      @fail_row_values = []
    rescue => e
      raise FailRowSaveError.new("save_fail_rows_error, FileImportLog_#{@log.id}, processed: #{@log.cached_process_count},#{e.message}")
    end
  end
end