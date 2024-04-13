class Excel::RowHandler::BaseRowHandlerService
  include Api::Response

  def initialize(options = {})
    @user_id, @project_id, @log_id = options.values_at(:user_id, :project_id, :log_id)
  end
end
