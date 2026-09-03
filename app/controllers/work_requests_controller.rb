class WorkRequestsController < ApplicationController
  def show
    @work_request = WorkRequest
      .includes(:business, :required_skill, assignments: :staff_member)
      .find(params[:id])
  end

  def edit
    @work_request = WorkRequest.find(params[:id])
  end

  def update
    @work_request = WorkRequest.update_details!(
      id: params[:id],
      attributes: work_request_params
    )

    redirect_to @work_request, notice: "勤務依頼の備考を更新しました。"
  rescue ActiveRecord::RecordInvalid => error
    raise unless error.record.is_a?(WorkRequest)

    @work_request = error.record
    render :edit, status: :unprocessable_content
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_calendar_path, alert: "更新する勤務依頼が見つかりませんでした。"
  end

  private

  def work_request_params
    params.expect(work_request: [ :required_skill_id, :title, :starts_at, :ends_at, :required_staff_count, :status, :notes ])
  end
end
