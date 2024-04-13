class Issue::ImportExcelService < BaseService
  def initialize(opts = {})
    @file_path = opts[:file_path]
    @max_rows = opts[:max_rows]
    @tracker_ids = Hash[Tracker.pluck(:name, :id)]
    @status_ids = Hash[IssueStatus.pluck(:name, :id)]
    @priority_ids = Hash[IssuePriority.pluck(:name, :id)]
    @batch_records = []
    @failed_count = 0
    @processing_count = 0
  end

  def call
    start_time = Time.now
    Roo::Excelx.new(@file_path).each_row_streaming(offset: 1, max_rows: @max_rows) do |row|
      @processing_count += 1
      build_record row
      import_record if (@processing_count % 1500) == 0
    end

    import_record if @batch_records.present?
    puts "开始时间：#{start_time}"
    end_time = Time.now
    puts "结束时间：#{end_time}"
    puts "耗时：#{end_time - start_time}秒"
    puts "总共：#{@processing_count}行，其中#{@failed_count}行导入失败"
    success_res
  end

  private

  def build_record(row)
    cells = row.map {|c| c.value }
    hs = { project_id: 1, author_id: 1}
    hs[:tracker_id] = @tracker_ids.fetch(cells.shift)
    hs[:subject] = cells.shift
    hs[:description] = cells.shift
    hs[:status_id] = @status_ids.fetch(cells.shift)
    hs[:priority_id] = @priority_ids.fetch(cells.shift)
    hs[:assigned_to_name] = cells.shift
    hs[:start_date] = Date.parse cells.shift
    hs[:due_date] = Date.parse cells.shift
    hs[:estimated_hours] = cells.shift.to_f
    hs[:done_ratio] = cells.shift.to_i
    @batch_records << hs
  end

  def import_record
    login_names = @batch_records.map{|hs| hs[:assigned_to_name]}
    login_ids = Hash[User.where(login: login_names).pluck(:login, :id)]
    @batch_records.each do |hs|
      hs[:assigned_to_id] = login_ids.fetch(hs.delete(:assigned_to_name))
    end
    res = Issue.import @batch_records
    @failed_count += res.failed_instances.size
    @batch_records = []
  end
end
