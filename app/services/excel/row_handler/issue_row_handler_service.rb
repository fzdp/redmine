class Excel::RowHandler::IssueRowHandlerService < Excel::RowHandler::BaseRowHandlerService
  def initialize(options = {})
    super
    raise "project_id not exist" if @project_id.blank?

    @tracker_ids = Hash[Tracker.pluck(:name, :id)]
    @status_ids = Hash[IssueStatus.pluck(:name, :id)]
    @priority_ids = Hash[IssuePriority.pluck(:name, :id)]
  end

  def call(cells)
    puts "=========== cells ============"
    puts cells

    hs = { project_id: @project_id, author_id: @user_id, file_import_log_id: @log_id }
    hs[:tracker_id] = @tracker_ids.fetch(cells.shift)
    hs[:subject] = cells.shift
    hs[:description] = cells.shift
    hs[:status_id] = @status_ids.fetch(cells.shift)
    hs[:priority_id] = @priority_ids.fetch(cells.shift)
    # todo add cache
    hs[:assigned_to_id] = User.find_by(login: cells.shift)&.id
    hs[:start_date] = Date.parse cells.shift
    hs[:due_date] = Date.parse cells.shift
    hs[:estimated_hours] = cells.shift.to_f
    hs[:done_ratio] = cells.shift.to_i

    i = Issue.create(hs)
    if i.valid?
      success_res
    else
      error_res(message: i.errors.full_messages)
    end
  end
end