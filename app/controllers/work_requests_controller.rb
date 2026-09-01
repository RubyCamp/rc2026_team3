class WorkRequestsController < ApplicationController
  def index
    @work_requests = WorkRequest
      .includes(:business, :required_skill, assignments: :staff_member)
      .order(:starts_at)
  end

  def new
    @work_request = WorkRequest.new
    @skills = Skill.all
  end

  def create
      @work_request = WorkRequest.create!(
        business_id: 1,
        required_skill_id: 1,
        starts_at: Time.current,
        ends_at: Time.current + 1.hour,
        required_staff_count: 1,
        title: "勤務依頼",
        notes: work_request_params[:notes]
      )

      redirect_to @work_request, notice: "勤務依頼を作成しました。"
    rescue ActiveRecord::RecordInvalid => error
      raise unless error.record.is_a?(WorkRequest)

      @work_request = error.record
      render :new, status: :unprocessable_content
  end


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
    redirect_to work_requests_path, alert: "更新する勤務依頼が見つかりませんでした。"
  end

  private

  def work_request_params
    params.expect(work_request: [ :notes ])
  end
end
