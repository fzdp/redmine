class FileImportLog < ApplicationRecord
  enum import_type: { issue: 0 }
  enum file_type: { xlsx: 0 }
  enum job_status: { created: 0, processing: 2, done: 1, exit: 3, fail_rows_error: 4 }

  serialize :headers

  KEY_PROCESS_COUNT = "sdmp:import:%s:processcnt"
  KEY_FAIL_COUNT = "sdmp:import:%s:failcnt"
  KEY_JOB_STATUS = "sdmp:import:%s:status"

  def incr_cached_process_count
    $redis.with {|c| c.incr(KEY_PROCESS_COUNT % self.id)}
  end

  def incr_cached_fail_count
    $redis.with {|c| c.incr(KEY_FAIL_COUNT % self.id)}
  end

  def cached_process_count
    $redis.with {|c| c.get(KEY_PROCESS_COUNT % self.id)&.to_i}
  end

  def cache_processing
    set_cached_job_status FileImportLog::job_statuses[:processing]
  end

  def cache_exit
    set_cached_job_status FileImportLog::job_statuses[:exit]
  end

  def cache_done
    set_cached_job_status FileImportLog::job_statuses[:done]
  end

  def cache_fail_rows_error
    set_cached_job_status FileImportLog::job_statuses[:fail_rows_error]
  end

  def cached_job_status
    $redis.with {|c| c.get(KEY_JOB_STATUS % self.id)}
  end

  def finish_del_cached
    pc, fc, js = $redis.with {|c| c.mget(KEY_PROCESS_COUNT % self.id, KEY_FAIL_COUNT % self.id, KEY_JOB_STATUS % self.id )}
    clear_cached_keys if update_columns(processed_count: pc.to_i, failed_count: fc.to_i, job_status: js, end_time: DateTime.now)
  end

  def save_headers(headers)
    self.update_column(:headers, headers)
  end

  private

  def set_cached_job_status(status)
    $redis.with {|c| c.set(KEY_JOB_STATUS % self.id, status)}
  end

  def clear_cached_keys
    $redis.with {|c| c.del(KEY_PROCESS_COUNT % self.id, KEY_FAIL_COUNT % self.id, KEY_PROCESS_COUNT % self.id)}
  end
end