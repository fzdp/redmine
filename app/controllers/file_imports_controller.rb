class FileImportsController < ApplicationController
  protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token
  include Api::Response

  def import_excel
    puts "=========== import_excel ========="
    p params
    if params[:file].blank? || params[:import_type].blank?
      render json: error_res(message: "参数错误"), status: :bad_request and return
    end

    options = {
      file_path: params[:file].path, import_type: params[:import_type],
      page_url: request.url, original_name: params[:file].original_filename,
      user_id: User.current.id, project_id: params[:project_id], max_row: params[:max_row]
    }
    job_id = FileImportJob.perform_async(options)
    render json: success_res(data: { jid: job_id })
  end

  def job_status

  end
end
